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

.data :
{
    *(.data)
}

.bss :
{
    __bss_start = .;
    *(COMMON)
    *(.bss)
    __bss_end = .;
}

__end = .;

}

