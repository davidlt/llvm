; REQUIRES: object-emission
;
; RUN: llc -mtriple=x86_64-unknown-linux-gnu -O0 -filetype=obj < %s > %t
; RUN: llvm-dwarfdump %t | FileCheck %s

; Test case derived from compiling the following source with clang -g:
;
; namespace pr14763 {
; struct foo {
;   foo(const foo&);
; };
;
; foo func(foo f) {
;   return f; // reference 'f' for now because otherwise we hit another bug
; }
;
; void sink(void*);
;
; void func2(bool b, foo g) {
;   if (b)
;     sink(&g); // reference 'f' for now because otherwise we hit another bug
; }
; }

; CHECK: debug_info contents
; 0x74 is DW_OP_breg4, showing that the parameter is accessed indirectly
; (with a zero offset) from the register parameter
; CHECK: DW_AT_location{{.*}}(<0x0{{.}}> 74 00
; CHECK-NOT: DW_TAG
; CHECK: DW_AT_name{{.*}} = "f"

; CHECK: DW_AT_location{{.*}}([[G_LOC:0x[0-9]*]])
; CHECK-NOT: DW_TAG
; CHECK: DW_AT_name{{.*}} = "g"
; CHECK: debug_loc contents
; CHECK-NEXT: [[G_LOC]]: Beginning
; CHECK-NEXT:               Ending
; CHECK-NEXT: Location description: 74 00

%"struct.pr14763::foo" = type { i8 }

; Function Attrs: uwtable
define void @_ZN7pr147634funcENS_3fooE(%"struct.pr14763::foo"* noalias sret %agg.result, %"struct.pr14763::foo"* %f) #0 {
entry:
  call void @llvm.dbg.declare(metadata !{%"struct.pr14763::foo"* %f}, metadata !22, metadata !{metadata !"0x102"}), !dbg !24
  call void @_ZN7pr147633fooC1ERKS0_(%"struct.pr14763::foo"* %agg.result, %"struct.pr14763::foo"* %f), !dbg !25
  ret void, !dbg !25
}

; Function Attrs: nounwind readnone
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

declare void @_ZN7pr147633fooC1ERKS0_(%"struct.pr14763::foo"*, %"struct.pr14763::foo"*) #2

; Function Attrs: uwtable
define void @_ZN7pr147635func2EbNS_3fooE(i1 zeroext %b, %"struct.pr14763::foo"* %g) #0 {
entry:
  %b.addr = alloca i8, align 1
  %frombool = zext i1 %b to i8
  store i8 %frombool, i8* %b.addr, align 1
  call void @llvm.dbg.declare(metadata !{i8* %b.addr}, metadata !26, metadata !{metadata !"0x102"}), !dbg !27
  call void @llvm.dbg.declare(metadata !{%"struct.pr14763::foo"* %g}, metadata !28, metadata !{metadata !"0x102"}), !dbg !27
  %0 = load i8* %b.addr, align 1, !dbg !29
  %tobool = trunc i8 %0 to i1, !dbg !29
  br i1 %tobool, label %if.then, label %if.end, !dbg !29

if.then:                                          ; preds = %entry
  %1 = bitcast %"struct.pr14763::foo"* %g to i8*, !dbg !31
  call void @_ZN7pr147634sinkEPv(i8* %1), !dbg !31
  br label %if.end, !dbg !31

if.end:                                           ; preds = %if.then, %entry
  ret void, !dbg !32
}

declare void @_ZN7pr147634sinkEPv(i8*) #2

attributes #0 = { uwtable "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf"="true" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone }
attributes #2 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf"="true" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!21, !33}

!0 = metadata !{metadata !"0x11\004\00clang version 3.4 \000\00\000\00\001", metadata !1, metadata !2, metadata !2, metadata !3, metadata !2, metadata !2} ; [ DW_TAG_compile_unit ] [/tmp/pass.cpp] [DW_LANG_C_plus_plus]
!1 = metadata !{metadata !"pass.cpp", metadata !"/tmp"}
!2 = metadata !{}
!3 = metadata !{metadata !4, metadata !17}
!4 = metadata !{metadata !"0x2e\00func\00func\00_ZN7pr147634funcENS_3fooE\006\000\001\000\006\00256\000\006", metadata !1, metadata !5, metadata !6, null, void (%"struct.pr14763::foo"*, %"struct.pr14763::foo"*)* @_ZN7pr147634funcENS_3fooE, null, null, metadata !2} ; [ DW_TAG_subprogram ] [line 6] [def] [func]
!5 = metadata !{metadata !"0x39\00pr14763\001", metadata !1, null} ; [ DW_TAG_namespace ] [pr14763] [line 1]
!6 = metadata !{metadata !"0x15\00\000\000\000\000\000\000", i32 0, null, null, metadata !7, null, null, null} ; [ DW_TAG_subroutine_type ] [line 0, size 0, align 0, offset 0] [from ]
!7 = metadata !{metadata !8, metadata !8}
!8 = metadata !{metadata !"0x13\00foo\002\008\008\000\000\000", metadata !1, metadata !5, null, metadata !9, null, null, null} ; [ DW_TAG_structure_type ] [foo] [line 2, size 8, align 8, offset 0] [def] [from ]
!9 = metadata !{metadata !10}
!10 = metadata !{metadata !"0x2e\00foo\00foo\00\003\000\000\000\006\00256\000\003", metadata !1, metadata !8, metadata !11, null, null, null, i32 0, metadata !16} ; [ DW_TAG_subprogram ] [line 3] [foo]
!11 = metadata !{metadata !"0x15\00\000\000\000\000\000\000", i32 0, null, null, metadata !12, null, null, null} ; [ DW_TAG_subroutine_type ] [line 0, size 0, align 0, offset 0] [from ]
!12 = metadata !{null, metadata !13, metadata !14}
!13 = metadata !{metadata !"0xf\00\000\0064\0064\000\001088", i32 0, null, metadata !8} ; [ DW_TAG_pointer_type ] [line 0, size 64, align 64, offset 0] [artificial] [from foo]
!14 = metadata !{metadata !"0x10\00\000\000\000\000\000", null, null, metadata !15} ; [ DW_TAG_reference_type ] [line 0, size 0, align 0, offset 0] [from ]
!15 = metadata !{metadata !"0x26\00\000\000\000\000\000", null, null, metadata !8} ; [ DW_TAG_const_type ] [line 0, size 0, align 0, offset 0] [from foo]
!16 = metadata !{i32 786468}
!17 = metadata !{metadata !"0x2e\00func2\00func2\00_ZN7pr147635func2EbNS_3fooE\0012\000\001\000\006\00256\000\0012", metadata !1, metadata !5, metadata !18, null, void (i1, %"struct.pr14763::foo"*)* @_ZN7pr147635func2EbNS_3fooE, null, null, metadata !2} ; [ DW_TAG_subprogram ] [line 12] [def] [func2]
!18 = metadata !{metadata !"0x15\00\000\000\000\000\000\000", i32 0, null, null, metadata !19, null, null, null} ; [ DW_TAG_subroutine_type ] [line 0, size 0, align 0, offset 0] [from ]
!19 = metadata !{null, metadata !20, metadata !8}
!20 = metadata !{metadata !"0x24\00bool\000\008\008\000\000\002", null, null} ; [ DW_TAG_base_type ] [bool] [line 0, size 8, align 8, offset 0, enc DW_ATE_boolean]
!21 = metadata !{i32 2, metadata !"Dwarf Version", i32 3}
!22 = metadata !{metadata !"0x101\00f\0016777222\008192", metadata !4, metadata !23, metadata !8} ; [ DW_TAG_arg_variable ] [f] [line 6]
!23 = metadata !{metadata !"0x29", metadata !1}         ; [ DW_TAG_file_type ] [/tmp/pass.cpp]
!24 = metadata !{i32 6, i32 0, metadata !4, null}
!25 = metadata !{i32 7, i32 0, metadata !4, null}
!26 = metadata !{metadata !"0x101\00b\0016777228\000", metadata !17, metadata !23, metadata !20} ; [ DW_TAG_arg_variable ] [b] [line 12]
!27 = metadata !{i32 12, i32 0, metadata !17, null}
!28 = metadata !{metadata !"0x101\00g\0033554444\008192", metadata !17, metadata !23, metadata !8} ; [ DW_TAG_arg_variable ] [g] [line 12]
!29 = metadata !{i32 13, i32 0, metadata !30, null}
!30 = metadata !{metadata !"0xb\0013\000\000", metadata !1, metadata !17} ; [ DW_TAG_lexical_block ] [/tmp/pass.cpp]
!31 = metadata !{i32 14, i32 0, metadata !30, null}
!32 = metadata !{i32 15, i32 0, metadata !17, null}
!33 = metadata !{i32 1, metadata !"Debug Info Version", i32 2}
