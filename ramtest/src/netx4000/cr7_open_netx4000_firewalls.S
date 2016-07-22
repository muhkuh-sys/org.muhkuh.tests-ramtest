#include "netx_io_areas.S"

	.section .init_code, "ax"
	.arm

	.extern test_main
	.extern stack_top

	.global start

@--------------------------------------

  .func start

start:
	stmfd   sp!, {r0, r1, r2, r3, lr}

	@ enable all firewall into netX area

	/* Disable all 10 firewalls into netX area for all masters */
	/* addresses 0xf40801B0 - 0xf40801D4*/
    ldr     r2, =HOSTADR(asic_ctrl_access_key)

    /* Control access to netx_ram0 */
    ldr     r0, =HOSTADR(firewall_cfg_netx_ram0)
    ldr     r1, =0xFF  @ allow all masters
    ldr     r3, [r2]
    str     r3, [r2]
    str     r1, [r0]

    /* Control access to netx_ram1 */
    ldr     r0, =HOSTADR(firewall_cfg_netx_ram1)
    ldr     r1, =0xFF  @ allow all masters
    ldr     r3, [r2]
    str     r3, [r2]
    str     r1, [r0]

    /* Control access to netx_ram2 */
    ldr     r0, =HOSTADR(firewall_cfg_netx_ram2)
    ldr     r1, =0xFF  @ allow all masters
    ldr     r3, [r2]
    str     r3, [r2]
    str     r1, [r0]

    /* Control access to netx_ramhs0 */
    ldr     r0, =HOSTADR(firewall_cfg_netx_ramhs0)
    ldr     r1, =0xFF  @ allow all masters
    ldr     r3, [r2]
    str     r3, [r2]
    str     r1, [r0]

    /* Control access to netx_ramhs1 */
    ldr     r0, =HOSTADR(firewall_cfg_netx_ramhs1)
    ldr     r1, =0xFF  @ allow all masters
    ldr     r3, [r2]
    str     r3, [r2]
    str     r1, [r0]

    /* Control access to netx_rameth */
    ldr     r0, =HOSTADR(firewall_cfg_netx_rameth)
    ldr     r1, =0xFF  @ allow all masters
    ldr     r3, [r2]
    str     r3, [r2]
    str     r1, [r0]

    /* Control access to netx_extmem */
    ldr     r0, =HOSTADR(firewall_cfg_netx_extmem)
    ldr     r1, =0xFF  @ allow all masters
    ldr     r3, [r2]
    str     r3, [r2]
    str     r1, [r0]

    /* Control access to netx_hifmem */
    ldr     r0, =HOSTADR(firewall_cfg_netx_hifmem)
    ldr     r1, =0xFF  @ allow all masters
    ldr     r3, [r2]
    str     r3, [r2]
    str     r1, [r0]

    /* Control access to netx_xc_config */
    ldr     r0, =HOSTADR(firewall_cfg_netx_xc_config)
    ldr     r1, =0xFF  @ allow all masters
    ldr     r3, [r2]
    str     r3, [r2]
    str     r1, [r0]

    /* Control access to netx_reg */
    ldr     r0, =HOSTADR(firewall_cfg_netx_reg)
    ldr     r1, =0xFF  @ allow all masters
    ldr     r3, [r2]
    str     r3, [r2]
    str     r1, [r0]

   /* return into ROM loader and proceed with chunk processing*/
	ldmfd   sp!, {r0, r1, r2, r3, lr}
	bx      lr

  .endfunc

@--------------------------------------

  .end

