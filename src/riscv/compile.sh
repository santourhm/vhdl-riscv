#!/bin/bash
set -e  

echo "Cleaning previous build..."
find . -name "*.cf" -delete

echo "Creating work library..."
ghdl -i --std=08 --work=work --workdir=work 

echo "Analyzing files in correct order..."

ghdl -a --std=08 --work=work --workdir=work riscv_types.vhd
ghdl -a --std=08 --work=work --workdir=work riscv_config.vhd

ghdl -a --std=08  -fsynopsys  --work=work --workdir=work ram/mem_ram_pkg.vhd
ghdl -a --std=08 -fsynopsys --work=work  --workdir=work rom/mem_rom_pkg.vhd
ghdl -a --std=08 -fsynopsys --work=work  --workdir=work regs/registers_pkg.vhd
ghdl -a --std=08 -fsynopsys --work=work  --workdir=work store/mem_store_pkg.vhd
ghdl -a --std=08 -fsynopsys --work=work  --workdir=work load/mem_load_pkg.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work decode/decoder_pkg.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work imm/immediate_pkg.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work fetch/fetch_pkg.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work alu/alu_pkg.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work csr/csr_registers_pkg.vhd

ghdl -a --std=08 -fsynopsys --work=work --workdir=work fetch/fetch.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work decode/decoder.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work alu/alu.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work csr/csr_registers.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work imm/immediate.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work forward/reg_forward.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work addr_stack/addr_stack.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work ram/mem_ram.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work rom/mem_rom.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work regs/registers.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work regs/registers_pass.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work load/mem_load.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work store/mem_store.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work csr/cnt_cycles.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work csr/cnt_instr.vhd
ghdl -a --std=08 -fsynopsys --work=work --workdir=work csr/csr_registers.vhd

# Top-level design
ghdl -a -fsynopsys --work=work --workdir=work --std=08  riscv.vhd 
ghdl -e -fsynopsys --work=work --workdir=work --std=08  riscv

ghdl -r -fsynopsys --work=work --workdir=work --std=08  riscv --wave=risc_wave.ghw
 

echo "Compilation finished successfully."
    