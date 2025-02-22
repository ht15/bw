ffi_sources = """
src/prep_cif.c
src/closures.c
""".split()

ffi_platforms = {
    'MIPS_IRIX': ['src/mips/ffi.c', 'src/mips/o32.S', 'src/mips/n32.S'],
    'MIPS_LINUX': ['src/mips/ffi.c', 'src/mips/o32.S'],
    'X86': ['src/x86/ffi.c', 'src/x86/sysv.S'],
    'X86_FREEBSD': ['src/x86/ffi.c', 'src/x86/freebsd.S'],
    'X86_WIN32': ['src/x86/ffi.c', 'src/x86/win32.S'],
    'SPARC': ['src/sparc/ffi.c', 'src/sparc/v8.S', 'src/sparc/v9.S'],
    'ALPHA': ['src/alpha/ffi.c', 'src/alpha/osf.S'],
    'IA64': ['src/ia64/ffi.c', 'src/ia64/unix.S'],
    'M32R': ['src/m32r/sysv.S', 'src/m32r/ffi.c'],
    'M68K': ['src/m68k/ffi.c', 'src/m68k/sysv.S'],
    'POWERPC': ['src/powerpc/ffi.c', 'src/powerpc/sysv.S', 'src/powerpc/ppc_closure.S', 'src/powerpc/linux64.S', 'src/powerpc/linux64_closure.S'],
    'POWERPC_AIX': ['src/powerpc/ffi.c', 'src/powerpc/aix.S', 'src/powerpc/aix_closure.S'],
    'POWERPC_FREEBSD': ['src/powerpc/ffi.c', 'src/powerpc/sysv.S', 'src/powerpc/ppc_closure.S'],
    'ARM': ['src/arm/sysv.S', 'src/arm/ffi.c'],
    'LIBFFI_CRIS': ['src/cris/sysv.S', 'src/cris/ffi.c'],
    'FRV': ['src/frv/eabi.S', 'src/frv/ffi.c'],
    'S390': ['src/s390/sysv.S', 'src/s390/ffi.c'],
    'X86_64': ['src/x86/ffi64.c', 'src/x86/unix64.S', 'src/x86/ffi.c', 'src/x86/sysv.S'],
    'SH': ['src/sh/sysv.S', 'src/sh/ffi.c'],
    'SH64': ['src/sh64/sysv.S', 'src/sh64/ffi.c'],
    'PA': ['src/pa/linux.S', 'src/pa/ffi.c'],
    'PA_LINUX': ['src/pa/linux.S', 'src/pa/ffi.c'],
    'PA_HPUX': ['src/pa/hpux32.S', 'src/pa/ffi.c'],
}

ffi_sources += ffi_platforms['X86_64']

ffi_cflags = '-I/usr/local/gcc-10.2/include  -Wall -fexceptions'
