ENTRY(_start)

SECTIONS
{
. = 1M;

.mb2_hdr :
{
    KEEP(*(.mb2_hdr))
}

.mb2_text :
{
    *(.mb2_text)
}

.text :
{
    *(.text)
}

.rodata :
{
    *(.rodata)
}

.data : ALIGN(4K)
{
    *(.data)
}

.bss : ALIGN(4K)
{
    __bss_start = .;
    *(COMMON)
    *(.bss)
    __bss_end = .;
}

__end = .;

}

