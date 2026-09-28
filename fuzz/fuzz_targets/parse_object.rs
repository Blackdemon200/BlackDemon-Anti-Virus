#![no_main]
//! Fuzz the ELF and Mach-O object parsers.
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let _ = blackdemon_parsers::elf::ElfInfo::parse(data);
    let _ = blackdemon_parsers::macho::MachoInfo::parse(data);
});
