;; RUN: opt -rewrite-statepoints-for-gc -verify -S < %s | FileCheck %s

;; This test is to verify that RewriteStatepointsForGC correctly relocates values
;; defined by invoke instruction results. 

declare i64* addrspace(1)* @non_gc_call()

declare void @gc_call()

declare i32* @fake_personality_function()

; Function Attrs: nounwind
define i64* addrspace(1)* @test() gc "statepoint-example" {
entry:
  %obj = invoke i64* addrspace(1)* @non_gc_call()
          to label %normal_dest unwind label %unwind_dest

unwind_dest: 
  %lpad = landingpad { i8*, i32 } personality i32* ()* @fake_personality_function
          cleanup
  resume { i8*, i32 } undef

normal_dest:
;; CHECK-LABEL: normal_dest:
;; CHECK-NEXT: gc.statepoint
;; CHECK-NEXT: %obj.relocated = call coldcc i64* addrspace(1)*                                      
  %safepoint_token = call i32 (void ()*, i32, i32, ...) @llvm.experimental.gc.statepoint.p0f_isVoidf(void ()* @gc_call, i32 0, i32 0, i32 0, i32 5, i32 0, i32 -1, i32 0, i32 0, i32 0)
  ret i64* addrspace(1)* %obj
}

declare i32 @llvm.experimental.gc.statepoint.p0f_isVoidf(void ()*, i32, i32, ...)


