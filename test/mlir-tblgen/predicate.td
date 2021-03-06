// RUN: mlir-tblgen -gen-op-defs -I %S/../../include %s | FileCheck %s

include "mlir/IR/OpBase.td"

def I32OrF32 : Type<CPred<"{0}.isInteger(32) || {0}.isF32()">,
                    "32-bit integer or floating-point type">;
def I32OrF32Tensor : TypedTensor<I32OrF32>;

def AllOfPredOp : Op<"identity_i32", [PredOpTrait<"both first and second holds",
      AllOf<[CPred<"first">, CPred<"second">]>>]> {
  let arguments = (ins Tensor:$x);
  let results = (outs Tensor:$y);
}

def TautologyElementTest: PredOpTrait<
  "first operand is a vector or tensor with the same elemental type as itself",
  TCopVTEtIsSameAs<0, 0>>;

def OperandAndResultElementTypeTest : PredOpTrait<
   "first operand is a vector or tensor with the same elemental type as first result",
   TCresVTEtIsSameAsOp<0, 0>>;

def Identity : Op<"identity", [TautologyElementTest, OperandAndResultElementTypeTest]> {
  let arguments = (ins
      I32OrF32Tensor:$x);
  let results = (outs
      I32OrF32Tensor:$y);
}

def IdentityI32 : Op<"identity_i32", [PredOpTrait<
    "first operand has i32 element type", TCopVTEtIs<0, I32>>]> {
  let arguments = (ins Tensor:$x);
  let results = (outs Tensor:$y);
}

// CHECK-LABEL: AllOfPredOp::verify
// CHECK: if (!(((first)) && ((second))))

// CHECK-LABEL: Identity::verify
// Verify arg constraints.
// CHECK: this->getOperation()->getOperand(0)->getType().cast<TensorType>().getElementType().isInteger(32) ||
// CHECK-SAME: this->getOperation()->getOperand(0)->getType().cast<TensorType>().getElementType().isF32()
// Verify tautology constraint.
// CHECK: if (!((((*this->getOperation()).getNumOperands() > std::max(0,0))) && (((*this->getOperation()).getOperand(0)->getType().isa<VectorOrTensorType>())) && (((*this->getOperation()).getOperand(0)->getType().isa<VectorOrTensorType>())) && (((*this->getOperation()).getOperand(0)->getType().cast<VectorOrTensorType>().getElementType() == (*this->getOperation()).getOperand(0)->getType().cast<VectorOrTensorType>().getElementType()))))
// CHECK-NEXT: return emitOpError("failed to verify that first operand is a vector or tensor with the same elemental type as itself");
// Verify OperandAndResultElementTypeTest constraint
// CHECK: if (!((((*this->getOperation()).getNumResults() > 0)) && (((*this->getOperation()).getNumOperands() > 0)) && (((*this->getOperation()).getResult(0)->getType().isa<VectorOrTensorType>())) && (((*this->getOperation()).getOperand(0)->getType().isa<VectorOrTensorType>())) && (((*this->getOperation()).getResult(0)->getType().cast<VectorOrTensorType>().getElementType() == (*this->getOperation()).getOperand(0)->getType().cast<VectorOrTensorType>().getElementType()))))
// CHECK-NEXT: return emitOpError("failed to verify that first operand is a vector or tensor with the same elemental type as first result");

// CHECK-LABEL: IdentityI32::verify
// CHECK: if (!((((*this->getOperation()).getNumOperands() > 0)) && (((*this->getOperation()).getOperand(0)->getType().isa<VectorOrTensorType>())) && (((*this->getOperation()).getOperand(0)->getType().cast<VectorOrTensorType>().getElementType().isInteger(32)))))
// CHECK-NEXT: return emitOpError("failed to verify that first operand has i32 element type");

def OpA : Op<"op_for_int_min_val", []> {
  let arguments = (ins Confined<I32Attr, [IntMinValue<10>]>:$attr);
}

// CHECK-LABEL: OpA::verify()
// CHECK:       if (!(((true)) && ((this->getAttr("attr").cast<IntegerAttr>().getInt() >= 10))))
// CHECK-SAME:    return emitOpError("attribute 'attr' failed to satisfy 32-bit integer whose minimal value is 10 attribute constraints");

def OpB : Op<"op_for_arr_min_count", []> {
  let arguments = (ins Confined<ArrayAttr, [ArrayMinCount<8>]>:$attr);
}

// CHECK-LABEL: OpB::verify()
// CHECK:       if (!(((true)) && ((this->getAttr("attr").cast<ArrayAttr>().size() >= 8))))
// CHECK-SAME:    return emitOpError("attribute 'attr' failed to satisfy array with at least 8 elements attribute constraints");

