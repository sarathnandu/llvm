//===- ShapeToStandard.cpp - conversion from Shape to Standard dialect ----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Conversion/ShapeToStandard/ShapeToStandard.h"

#include "../PassDetail.h"
#include "mlir/Dialect/SCF/SCF.h"
#include "mlir/Dialect/Shape/IR/Shape.h"
#include "mlir/Dialect/StandardOps/IR/Ops.h"
#include "mlir/Transforms/DialectConversion.h"

using namespace mlir;
using namespace mlir::shape;

/// Conversion patterns.
namespace {
class AnyOpConversion : public OpConversionPattern<AnyOp> {
public:
  using OpConversionPattern<AnyOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(AnyOp op, ArrayRef<Value> operands,
                  ConversionPatternRewriter &rewriter) const override;
};
} // namespace

LogicalResult
AnyOpConversion::matchAndRewrite(AnyOp op, ArrayRef<Value> operands,
                                 ConversionPatternRewriter &rewriter) const {
  AnyOp::Adaptor transformed(operands);

  // Replace `any` with its first operand.
  // Any operand would be a valid substitution.
  rewriter.replaceOp(op, {transformed.inputs().front()});
  return success();
}

namespace {
template <typename SrcOpTy, typename DstOpTy>
class BinaryOpConversion : public OpConversionPattern<SrcOpTy> {
public:
  using OpConversionPattern<SrcOpTy>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(SrcOpTy op, ArrayRef<Value> operands,
                  ConversionPatternRewriter &rewriter) const override {
    typename SrcOpTy::Adaptor adaptor(operands);
    rewriter.replaceOpWithNewOp<DstOpTy>(op, adaptor.lhs(), adaptor.rhs());
    return success();
  }
};
} // namespace

namespace {
class ShapeOfOpConversion : public OpConversionPattern<ShapeOfOp> {
public:
  using OpConversionPattern<ShapeOfOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ShapeOfOp op, ArrayRef<Value> operands,
                  ConversionPatternRewriter &rewriter) const override;
};
} // namespace

LogicalResult ShapeOfOpConversion::matchAndRewrite(
    ShapeOfOp op, ArrayRef<Value> operands,
    ConversionPatternRewriter &rewriter) const {
  ShapeOfOp::Adaptor transformed(operands);
  auto loc = op.getLoc();
  auto tensorVal = transformed.arg();
  auto tensorTy = tensorVal.getType();

  // For unranked tensors `shape_of` lowers to `scf` and the pattern can be
  // found in the corresponding pass.
  if (tensorTy.isa<UnrankedTensorType>())
    return failure();

  // Build values for individual dimensions.
  SmallVector<Value, 8> dimValues;
  auto rankedTensorTy = tensorTy.cast<RankedTensorType>();
  int64_t rank = rankedTensorTy.getRank();
  for (int64_t i = 0; i < rank; i++) {
    if (rankedTensorTy.isDynamicDim(i)) {
      auto dimVal = rewriter.create<DimOp>(loc, tensorVal, i);
      dimValues.push_back(dimVal);
    } else {
      int64_t dim = rankedTensorTy.getDimSize(i);
      auto dimVal = rewriter.create<ConstantIndexOp>(loc, dim);
      dimValues.push_back(dimVal);
    }
  }

  // Materialize extent tensor.
  Value staticExtentTensor =
      rewriter.create<TensorFromElementsOp>(loc, dimValues);
  rewriter.replaceOpWithNewOp<TensorCastOp>(op, staticExtentTensor,
                                            op.getType());
  return success();
}

namespace {
class GetExtentOpConverter : public OpConversionPattern<GetExtentOp> {
  using OpConversionPattern<GetExtentOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(GetExtentOp op, ArrayRef<Value> operands,
                  ConversionPatternRewriter &rewriter) const override;
};
} // namespace

LogicalResult GetExtentOpConverter::matchAndRewrite(
    GetExtentOp op, ArrayRef<Value> operands,
    ConversionPatternRewriter &rewriter) const {
  GetExtentOp::Adaptor transformed(operands);

  // Derive shape extent directly from shape origin if possible.
  // This circumvents the necessity to materialize the shape in memory.
  if (auto shapeOfOp = op.shape().getDefiningOp<ShapeOfOp>()) {
    rewriter.replaceOpWithNewOp<DimOp>(op, shapeOfOp.arg(), transformed.dim());
    return success();
  }

  rewriter.replaceOpWithNewOp<ExtractElementOp>(op, rewriter.getIndexType(),
                                                transformed.shape(),
                                                ValueRange{transformed.dim()});
  return success();
}

namespace {
class RankOpConverter : public OpConversionPattern<shape::RankOp> {
public:
  using OpConversionPattern<shape::RankOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(shape::RankOp op, ArrayRef<Value> operands,
                  ConversionPatternRewriter &rewriter) const override;
};
} // namespace

LogicalResult
RankOpConverter::matchAndRewrite(shape::RankOp op, ArrayRef<Value> operands,
                                 ConversionPatternRewriter &rewriter) const {
  shape::RankOp::Adaptor transformed(operands);
  rewriter.replaceOpWithNewOp<DimOp>(op, transformed.shape(), 0);
  return success();
}

namespace {
/// Type conversions.
class ShapeTypeConverter : public TypeConverter {
public:
  using TypeConverter::convertType;

  ShapeTypeConverter(MLIRContext *ctx) {
    // Add default pass-through conversion.
    addConversion([&](Type type) { return type; });

    addConversion([ctx](SizeType type) { return IndexType::get(ctx); });
    addConversion([ctx](ShapeType type) {
      return RankedTensorType::get({ShapedType::kDynamicSize},
                                   IndexType::get(ctx));
    });
  }
};
} // namespace

namespace {
/// Conversion pass.
class ConvertShapeToStandardPass
    : public ConvertShapeToStandardBase<ConvertShapeToStandardPass> {

  void runOnOperation() override;
};
} // namespace

void ConvertShapeToStandardPass::runOnOperation() {
  // Setup type conversion.
  MLIRContext &ctx = getContext();
  ShapeTypeConverter typeConverter(&ctx);

  // Setup target legality.
  ConversionTarget target(ctx);
  target.addLegalDialect<scf::SCFDialect, StandardOpsDialect>();
  target.addLegalOp<ModuleOp, ModuleTerminatorOp, ReturnOp>();
  target.addDynamicallyLegalOp<FuncOp>([&](FuncOp op) {
    return typeConverter.isSignatureLegal(op.getType()) &&
           typeConverter.isLegal(&op.getBody());
  });

  // Setup conversion patterns.
  OwningRewritePatternList patterns;
  populateShapeToStandardConversionPatterns(patterns, &ctx);
  populateFuncOpTypeConversionPattern(patterns, &ctx, typeConverter);

  // Apply conversion.
  auto module = getOperation();
  if (failed(applyFullConversion(module, target, patterns)))
    signalPassFailure();
}

void mlir::populateShapeToStandardConversionPatterns(
    OwningRewritePatternList &patterns, MLIRContext *ctx) {
  // clang-format off
  patterns.insert<
      AnyOpConversion,
      BinaryOpConversion<AddOp, AddIOp>,
      BinaryOpConversion<MulOp, MulIOp>,
      GetExtentOpConverter,
      RankOpConverter,
      ShapeOfOpConversion>(ctx);
  // clang-format on
}

std::unique_ptr<OperationPass<ModuleOp>>
mlir::createConvertShapeToStandardPass() {
  return std::make_unique<ConvertShapeToStandardPass>();
}
