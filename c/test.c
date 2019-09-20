#include "glb.h"
#include <stdio.h>
#include "test.h"

void test_alu_16(){
    i16 ia;
    i16 ib;
    u16 ua;
    u16 ub;
    i16 ic = 0;
    u16 uc = 0;
    i16 i;
    u16 target_sum = 0xf*0x8*0x12;
    printf("Test 16 bit ALU\n");

    for(i=0xf;i>=0;i--){
        ia = i;
        ib = i*0x11;
        ua = i;
        ub = i*0x11;
        ic = ic + ia + ib;
        uc = uc + ua + ub;
        printf("%d %u\n",ic,uc);
        printf("%d>>3=%d\n",ic,ic>>3);
        printf("%d<<1=%d\n",ic,ic<<1);
        printf("%d^%d=%d\n",uc,uc,uc^uc);
    }
    if(ic != target_sum){
        printf("ic error,it is %d\n",ic);
    }else{
        printf(".");
    }
    if(uc != target_sum){
        printf("ic error,it is %d\n",uc);
    }else{
        printf(".");
    }
    printf("\n");

}

void test_alu_32(){
    i32 ia;
    i32 ib;
    u32 ua;
    u32 ub;
    i32 ic = 0;
    u32 uc = 0;
    u32 i;
    u32 target_sum = 0xff*0x80*0x102;

    printf("Test 32 bit ALU\n");
    for(i=0;i<0x100;i++){
        ia = i;
        ib = i*0x101;
        ua = i;
        ub = i*0x101;
        ic = ic + ia + ib;
        uc = uc + ua + ub;
        printf("%d>>3=%d\n",ic,ic>>3);
        printf("%d<<1=%d\n",ic,ic<<1);
        printf("%d^%d=%d\n",uc,uc>>1,uc^(uc>>1));
        printf("%d %u\n",ic,uc);
    }
    if(ic != target_sum){
        printf("ic error,it is %d\n",ic);
    }else{
        printf(".");
    }
    if(uc != target_sum){
        printf("ic error,it is %d\n",uc);
    }else{
        printf(".");
    }
    printf("\n");
}

void test_uiapc(){
    u32 pc_symbol, pc_pc;
    pc_symbol = auipc_test(0);
    pc_pc = auipc_test(1);
    if (pc_symbol != pc_pc) {
        printf("auipc test failed, pc_symbol = %x, pc_pc = %x\n", pc_symbol, pc_pc);
    }
}

void test_load(){
    i8 data1 = -1;
    i16 data2 = -2;
    i32 data3 = -3;
    u8 data4 = 4;
    u16 data5 = 5;

    if (lb_test((u32)&data1) != data1) {
        printf("lb test failed, addr = %x, data %x != %x\n",(u32)&data1, data1, lb_test((u32)&data1));
    }
    if (lh_test((u32)&data2) != data2) {
        printf("lh test failed, addr = %x, data %x != %x\n",(u32)&data2, data2, lh_test((u32)&data2));
    }
    if (lw_test((u32)&data3) != data3) {
        printf("lw test failed, addr = %x, data %x != %x\n",(u32)&data3, data3, lw_test((u32)&data3));
    }
    if (lbu_test((u32)&data4) != data4) {
        printf("lbu test failed, addr = %x, data %x != %x\n",(u32)&data4, data4, lbu_test((u32)&data4));
    }
    if (lhu_test((u32)&data5) != data5) {
        printf("lhu test failed, addr = %x, data %x != %x\n",(u32)&data5, data5, lhu_test((u32)&data5));
    }
}

void test_imm(){
    i32 data = -1;

    if (addi_test(data) != 2){ //-1+3
        printf("addi test failed, data %d != 2\n",addi_test(data));
    }
    if (slti_test(data) != 1){ //-1 < 3 ? 1 : 0
        printf("slti test failed, data %d != 1\n",slti_test(data));
    }
    if (sltiu_test(data) != 0){ //0xffffffff < 3? 1 : 0
        printf("sltiu test failed, data %d != 0\n",sltiu_test(data));
    }
    if (xori_test(data) != -4){ //0xffffffff xor 3
        printf("xori test failed, data %d != -4\n",xori_test(data));
    }
    if (ori_test(data) != -1){ //-1 or 3
        printf("ori test failed, data %d != -1\n",ori_test(data));
    }
    if (slli_test(data) != -8){ //-1<<3 (logic)
        printf("slli test failed, data %d != -8\n",slli_test(data));
    }
    if (srli_test(data) != 0x1fffffff){ //-1>>3 (logic)
        printf("srli test failed, data 0x%x != 0x1fffffff\n",srli_test(data));
    }
    if (srai_test(data) != -1){ //-1>>3 (math)
        printf("srai test failed, data %d != -1\n",srai_test(data));
    }
}

void test(){
    test_alu_16();
    test_alu_32();
    test_uiapc();
    test_load();
    test_imm();
}
