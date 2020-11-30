//===--- ShadowObfuscator.h - Per-Module Obfuscation ------------*- C++ -*-===//
//
//  Written by github.com/nimrodpar
//
//===----------------------------------------------------------------------===//
//
// Header for the Shadow compiler obfuscations.
//
//===----------------------------------------------------------------------===//

#ifndef SHADOW_OBFUSCATOR_H
#define SHADOW_OBFUSCATOR_H

#include "llvm/IR/Module.h"
#include "llvm/IR/Constant.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/LLVMContext.h"

namespace clang {

namespace CodeGen {

class ShadowObfuscator {

private:

    llvm::Module &TheModule;
    unsigned char Seed;

    void DoGlobalString(llvm::GlobalVariable &Glob);
    llvm::Constant * EncodeString(llvm::StringRef StrVal);
    void AddGEPOpDecodeLogicForUser(llvm::GEPOperator *GEPOp, llvm::User *U);

public:
    ShadowObfuscator(llvm::Module &M) : TheModule(M) {
      srand(time(0));
      Seed = (unsigned char)rand();
    }

    void Obfuscate();

};

}  // end namespace CodeGen
}  // end namespace clang


#endif //SHADOW_OBFUSCATOR_H
