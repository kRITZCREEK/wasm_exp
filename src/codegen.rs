extern crate parity_wasm;
extern crate wabt;

use parity_wasm::builder::*;
use parity_wasm::elements::*;

fn gen_add() -> FunctionDefinition {
    FunctionBuilder::new()
        .signature()
        .with_param(ValueType::I32)
        .with_return_type(Some(ValueType::I32))
        .build()
        .body()
        .with_locals(vec![
            Local::new(1, ValueType::I32),
            Local::new(1, ValueType::I32),
        ])
        .with_instructions(Instructions::new(vec![
            Instruction::GetLocal(0),
            Instruction::I32Load16U(1, 0),
            Instruction::SetLocal(1),
            Instruction::GetLocal(1),
            Instruction::GetLocal(2),
            Instruction::I32Add,
            Instruction::End,
        ]))
        .build()
        .build()
}

fn gen_mod() -> Module {
    let mut m = ModuleBuilder::new();
    m.push_function(gen_add());
    m.build()
}

pub fn test_codegen() {
    let wasm = serialize(gen_mod()).unwrap();
    let wat = wabt::wasm2wat(&wasm).unwrap();
    println!("{}", wat)
}

// (func $add (param $args i32) (result i32)
//       (local $x i32)
//       (local $y i32)
//       (set_local $x (i32.load16_u (get_local $args)))
//       (set_local $y (i32.load16_u (i32.add (get_local $args) (i32.const 2))))
//       (i32.add (get_local $x) (get_local $y)))
