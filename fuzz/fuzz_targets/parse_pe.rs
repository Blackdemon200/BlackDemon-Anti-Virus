#![no_main]
//! Fuzz the PE parser + entropy on arbitrary bytes. Must never panic.
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let _ = blackdemon_parsers::FileFormat::detect(data);
    let _ = blackdemon_parsers::pe::PeInfo::parse(data);
    let _ = blackdemon_parsers::entropy::shannon(data);
});
