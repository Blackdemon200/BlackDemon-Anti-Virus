#![no_main]
//! Fuzz the container extraction layer (ZIP/GZIP/TAR/7z) on malformed archives.
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let _ = blackdemon_unpack::detect(data);
    let _ = blackdemon_unpack::try_extract(data, blackdemon_unpack::Limits::default());
});
