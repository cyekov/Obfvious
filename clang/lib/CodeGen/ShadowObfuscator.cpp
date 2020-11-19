//===--- ShadowObfuscator.h - Per-Module Obfuscation ------------*- C++ -*-===//
//
//  Written by github.com/nimrodpar
//
//===----------------------------------------------------------------------===//
//
// Shadow compiler obfuscations.
//
//===----------------------------------------------------------------------===//

#include "ShadowObfuscator.h"
#include "CodeGenModule.h"


using namespace llvm;
using namespace clang;
using namespace CodeGen;

void ShadowObfuscator::Obfuscate() {
    //vector<GlobalString*> GlobalStrings;
    auto &Ctx = TheModule.getContext();
    for(llvm::GlobalVariable &Glob : TheModule.globals()) {
        DoGlobalString(Glob, Ctx);
    }
}

void ShadowObfuscator::DoGlobalString(GlobalVariable &Glob, LLVMContext &Ctx) {

    if (!Glob.hasInitializer())
        return;

    // start by obfuscating the global
    Constant *Initializer = Glob.getInitializer();

    if (isa<ConstantDataArray>(Initializer)) {
        auto CDA = cast<ConstantDataArray>(Initializer);

        if (!CDA->isString())  // strings only, for now
            return;

        StringRef StrVal = CDA->getAsString();  // extract raw string
        outs() << "Obfuscating '" << *Initializer << "'\n";

        const char *Data = StrVal.begin();
        auto Size = StrVal.size();

        // the existing string initializer is const and can't be changed, so we need a replacement
        char *NewData = (char*)malloc(Size);
        for(unsigned int i = 0; i < Size; i++){
            NewData[i] = Data[i] + 1;
        }

        Constant *NewConst = ConstantDataArray::getString(Ctx, StringRef(NewData, Size), false);

        Glob.setInitializer(NewConst);  // Overwrite the global value
        //GlobalStrings.push_back(new GlobalString(&Glob));
        Glob.setConstant(false);
    }

    // now de-obfuscate each usage
    // TODO: cases where teh same string is used twice in the same function

    auto I8Type = llvm::Type::getInt8Ty(Ctx);
    auto I8PtrType = llvm::Type::getInt8PtrTy(Ctx);
    // lambdas for creating an LLVMIRy int constants (usually used for indexing)
    auto c8 = [&Ctx](int idx, bool isSigned = false) { return ConstantInt::get(IntegerType::get(Ctx, 8), idx, isSigned); };
    auto c64 = [&Ctx](int idx) { return ConstantInt::get(IntegerType::get(Ctx, 64), idx); };

    for (User *U : Glob.users()) {
        if (Instruction * Inst = dyn_cast<Instruction>(U)) {
            outs() << Glob << " is used in Instruction " << *Inst << "\n";
            assert(false);
        } else if (Operator * Op = dyn_cast<Operator>(U)) {
            if (GEPOperator * GEPOp = dyn_cast<GEPOperator>(Op)) {
                for (auto *OpU : Op->users()) {

                    Instruction * Inst = dyn_cast<Instruction>(OpU);
                    outs() << " |-- De-Obfuscating Usage @" << Inst->getFunction()->getName() << ": " << *U << "\n";

                    Function *UserFunc = Inst->getFunction();
                    BasicBlock *UserFuncEntryBlock = &(UserFunc->getEntryBlock());
                    BasicBlock *UserBBlock = Inst->getParent();

                    // Create blocks
                    // TODO: Randomize insertion location between entry and Inst (can use UserBBlock->splitBasicBlock(Inst))
                    auto *BEntry = BasicBlock::Create(Ctx, "entry", UserFunc, UserFuncEntryBlock);
                    auto *BWhileBody = BasicBlock::Create(Ctx, "while.body", UserFunc, UserFuncEntryBlock);
                    // Init block
                    IRBuilder<> *Builder = new IRBuilder<>(BEntry);

                    auto *deObfAlloc = Builder->CreateAlloca(GEPOp->getSourceElementType());

                    // the GEP requires 2 indexes:
                    // (i) the first is the offset from the deObfAlloc pointer to the start of the object (remember that the pointer could point to an array)
                    // (ii) the second is the offset to object that we want to load from, in this case the first char of the string
                    auto *deObfGEP = Builder->CreateGEP(deObfAlloc, { c64(0), c64(0) }, "deObfGEP");
                    auto *deObfPtr = Builder->CreatePointerCast(deObfGEP, I8PtrType);

                    // Cast the Global to i8* (it may be of [<length> * i8] type)
                    auto *StrPtr = Builder->CreatePointerCast(GEPOp->getPointerOperand(), I8PtrType);

                    // load the obfuscated global (the actual char at location 0)
                    auto *value0 = Builder->CreateLoad(StrPtr, "value0");

                    // check if null
                    auto *isValue0Null = Builder->CreateICmpEQ(value0, Constant::getNullValue(value0->getType()), "isValue0Null");
                    // jump accordingly
                    Builder->CreateCondBr(isValue0Null, UserFuncEntryBlock, BWhileBody);

                    delete Builder;

                    // DeObf block
                    Builder = new IRBuilder<>(BWhileBody);
                    // all PHI nodes must be created at top of block
                    // addressPhi is the pointer to the current index to the obfuscated string
                    // valuePhi is the char value at the current index to the obfuscated string
                    // storeAddressPhi is the pointer to the current index in the decoded string
                    PHINode *valuePhi = Builder->CreatePHI(I8Type, 2, "valuePhi");
                    PHINode *addressPhi = Builder->CreatePHI(I8PtrType, 2, "addressPhi");
                    PHINode *storeAddressPhi = Builder->CreatePHI(I8PtrType, 2, "storeAddressPhi");

                    // decode: decrease the char by 1
                    auto *sub = Builder->CreateSub(valuePhi, c8(1, true));

                    // advance the obfuscated and decoded string pointer by 1
                    auto *incAddress = Builder->CreateGEP(addressPhi, c64(1), "incAddress");
                    auto *incStoreAddress = Builder->CreateGEP(storeAddressPhi, c64(1), "incStoreAddress");

                    // store the decreased value at the current string pointer
                    Builder->CreateStore(sub, storeAddressPhi);

                    // load the char at the incremented index
                    auto *nextValue = Builder->CreateLoad(incAddress, "nextValue");
                    auto isValueNull = Builder->CreateICmpEQ(sub, c8(0), "isValueNull");

                    // replace the usages with the decoded string
                    for (unsigned i = 0; i < Inst->getNumOperands(); ++i) {
                        if (Inst->getOperand(i) == GEPOp) {
                            Inst->setOperand(i, deObfGEP);
                        }
                    }
                    // loop back (or end if \0)
                    Builder->CreateCondBr(isValueNull, UserFuncEntryBlock, BWhileBody);

                    delete Builder;

                    // fill in Phi nodes

                    // storeAddressPhi is equal to the decoded string at index 0 if arriving from init block and the current index + 1 if looping
                    storeAddressPhi->addIncoming(incStoreAddress, BWhileBody);
                    storeAddressPhi->addIncoming(deObfPtr, BEntry);

                    // addressPhi is equal to the obfuscated string at index 0 if arriving from init block and the current index + 1 if looping
                    addressPhi->addIncoming(StrPtr, BEntry);
                    addressPhi->addIncoming(incAddress, BWhileBody);

                    // valuePhi is equal to nextValue if arriving from deObf block, and value0 if arriving from init block
                    valuePhi->addIncoming(nextValue, BWhileBody);
                    valuePhi->addIncoming(value0, BEntry);
                }
            }

        } else if (auto * Const = dyn_cast<Constant>(U)) {
            outs() << Glob << " is used in Constant " << *Const << "\n";
            assert(false);
        } else {
            U->dump();
            assert(false && "Could not get user subtype");
        }
    }
}
