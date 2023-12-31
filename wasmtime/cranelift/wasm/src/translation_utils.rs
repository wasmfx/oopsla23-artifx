//! Helper functions and structures for the translation.
use crate::environ::TargetEnvironment;
use crate::WasmResult;
use core::u32;
use cranelift_codegen::ir;
use cranelift_frontend::FunctionBuilder;
#[cfg(feature = "enable-serde")]
use serde::{Deserialize, Serialize};
use wasmparser::{FuncValidator, WasmFuncType, WasmModuleResources};
use wasmtime_types::WasmType;

/// Get the parameter and result types for the given Wasm blocktype.
pub fn blocktype_params_results<'a, T>(
    validator: &'a FuncValidator<T>,
    ty: wasmparser::BlockType,
) -> WasmResult<(
    impl ExactSizeIterator<Item = wasmparser::ValType> + Clone + 'a,
    impl ExactSizeIterator<Item = wasmparser::ValType> + Clone + 'a,
)>
where
    T: WasmModuleResources,
{
    return Ok(match ty {
        wasmparser::BlockType::Empty => {
            let params: &'static [wasmparser::ValType] = &[];
            let results: std::vec::Vec<wasmparser::ValType> = vec![];
            (
                itertools::Either::Left(params.iter().copied()),
                itertools::Either::Left(results.into_iter()),
            )
        }
        wasmparser::BlockType::Type(ty) => {
            let params: &'static [wasmparser::ValType] = &[];
            let results: std::vec::Vec<wasmparser::ValType> = vec![ty.clone()];
            (
                itertools::Either::Left(params.iter().copied()),
                itertools::Either::Left(results.into_iter()),
            )
        }
        wasmparser::BlockType::FuncType(ty_index) => {
            let ty = validator
                .resources()
                .func_type_at(ty_index)
                .expect("should be valid");
            (
                itertools::Either::Right(ty.inputs()),
                itertools::Either::Right(ty.outputs()),
            )
        }
    });
}

/// Create a `Block` with the given Wasm parameters.
pub fn block_with_params<PE: TargetEnvironment + ?Sized>(
    builder: &mut FunctionBuilder,
    params: impl IntoIterator<Item = wasmparser::ValType>,
    environ: &PE,
) -> WasmResult<ir::Block> {
    let block = builder.create_block();
    for ty in params {
        match ty {
            wasmparser::ValType::I32 => {
                builder.append_block_param(block, ir::types::I32);
            }
            wasmparser::ValType::I64 => {
                builder.append_block_param(block, ir::types::I64);
            }
            wasmparser::ValType::F32 => {
                builder.append_block_param(block, ir::types::F32);
            }
            wasmparser::ValType::F64 => {
                builder.append_block_param(block, ir::types::F64);
            }
            wasmparser::ValType::Ref(rt) => {
                let hty = environ.convert_heap_type(rt.heap_type());
                builder.append_block_param(block, environ.reference_type(hty));
            }
            wasmparser::ValType::V128 => {
                builder.append_block_param(block, ir::types::I8X16);
            }
        }
    }
    Ok(block)
}

/// Turns a `wasmparser` `f32` into a `Cranelift` one.
pub fn f32_translation(x: wasmparser::Ieee32) -> ir::immediates::Ieee32 {
    ir::immediates::Ieee32::with_bits(x.bits())
}

/// Turns a `wasmparser` `f64` into a `Cranelift` one.
pub fn f64_translation(x: wasmparser::Ieee64) -> ir::immediates::Ieee64 {
    ir::immediates::Ieee64::with_bits(x.bits())
}

/// Special VMContext value label. It is tracked as 0xffff_fffe label.
pub fn get_vmctx_value_label() -> ir::ValueLabel {
    const VMCTX_LABEL: u32 = 0xffff_fffe;
    ir::ValueLabel::from_u32(VMCTX_LABEL)
}

/// Create a `Block` with the given Wasm parameters.
pub fn block_with_params_wasmtype<PE: TargetEnvironment + ?Sized>(
    builder: &mut FunctionBuilder,
    params: &[WasmType],
    environ: &PE,
) -> WasmResult<ir::Block> {
    let block = builder.create_block();
    for ty in params {
        match ty {
            WasmType::I32 => {
                builder.append_block_param(block, ir::types::I32);
            }
            WasmType::I64 => {
                builder.append_block_param(block, ir::types::I64);
            }
            WasmType::F32 => {
                builder.append_block_param(block, ir::types::F32);
            }
            WasmType::F64 => {
                builder.append_block_param(block, ir::types::F64);
            }
            WasmType::Ref(rt) => {
                builder.append_block_param(block, environ.reference_type(rt.heap_type));
            }
            WasmType::V128 => {
                builder.append_block_param(block, ir::types::I8X16);
            }
        }
    }
    Ok(block)
}

/// Create a synthetic suspend block (used to wrap a resume table).
pub fn suspend_block<PE: TargetEnvironment + ?Sized>(
    builder: &mut FunctionBuilder,
    _environ: &PE,
) -> WasmResult<ir::Block> {
    let block = builder.create_block();
    Ok(block)
}

/// Create a synthetic resume table entry block.
pub fn resumetable_entry_block<PE: TargetEnvironment + ?Sized>(
    builder: &mut FunctionBuilder,
    _environ: &PE,
) -> WasmResult<ir::Block> {
    let block = builder.create_block();
    Ok(block)
}

/// Create a synthetic resume table forwarding block.
pub fn resumetable_forwarding_block<PE: TargetEnvironment + ?Sized>(
    builder: &mut FunctionBuilder,
    _environ: &PE,
) -> WasmResult<ir::Block> {
    let block = builder.create_block();

    Ok(block)
}

/// Create a synthetic return block (used to wrap the return
/// continuation of resume).
pub fn return_block<PE: TargetEnvironment + ?Sized>(
    builder: &mut FunctionBuilder,
    _environ: &PE,
) -> WasmResult<ir::Block> {
    let block = builder.create_block();

    Ok(block)
}

/// Compute the maximum number of arguments that a suspension may
/// supply.
pub fn resumetable_max_num_tag_payloads<PE: crate::FuncEnvironment + ?Sized>(
    tags: &[u32],
    environ: &PE,
) -> WasmResult<usize> {
    Ok(tags
        .iter()
        .map(|tag| environ.tag_params(*tag).len())
        .max()
        .unwrap())
}
