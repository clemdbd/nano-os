/*
Copyright(c) 2017 Cedric Jimenez

This file is part of Nano-OS.

Nano-OS is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Nano-OS is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Nano-OS.  If not, see <http://www.gnu.org/licenses/>.
*/

    SECTION .nano_os_port_asm:CODE
	THUMB


	/** \brief Service call number for the first context switch */
	#define SVC_FIRST_CONTEXT_SWITCH 			0x24
	/** \brief Service call number to switch to priviledged mode */
	#define SVC_SWITCH_TO_PRIVILEDGED_MODE 		0xAA

	/** \brief MPU control register */
	#define MPU_CTRL_REG 0xE000ED94
	/** \brief MPU region base address register */
	#define MPU_RBAR_REG 0xE000ED9C

	PUBLIC NANO_OS_PORT_GetTaskStackPointer

	PUBLIC NANO_OS_PORT_SaveInterruptStatus
	PUBLIC NANO_OS_PORT_RestoreInterruptStatus

	PUBLIC NANO_OS_PORT_FirstContextSwitchAsm
	PUBLIC NANO_OS_PORT_ContextSwitch
	PUBLIC NANO_OS_PORT_ContextSwitchFromIsr

	PUBLIC NANO_OS_PORT_SwitchToPriviledgedMode
	PUBLIC NANO_OS_PORT_SwitchToUnpriviledgedMode

	PUBLIC NANO_OS_PORT_SvcHandler
	PUBLIC NANO_OS_PORT_PendSvHandler

    EXTERN g_nano_os




/* uint32_t NANO_OS_PORT_GetTaskStackPointer(void)
   Get the current value of the task stack pointer -> Register R0 */
NANO_OS_PORT_GetTaskStackPointer:

	mrs		r0, psp
	blx		lr



/* nano_os_int_status_reg_t NANO_OS_PORT_SaveInterruptStatus(void)
   Disable interrupts and return previous interrupt status register -> Register R0 */
NANO_OS_PORT_SaveInterruptStatus:

    mrs     r0, primask
    cpsid   i
    bx      lr


/* void NANO_OS_PORT_RestoreInterruptStatus(const nano_os_int_status_reg_t int_status_reg)
   Restore the interrupt status register passed in parameter -> Register R0 */
NANO_OS_PORT_RestoreInterruptStatus:

    msr     primask, r0
    bx      lr




/* void NANO_OS_PORT_SwitchToPriviledgedMode(void)
   Switch the CPU to priviledged mode */
NANO_OS_PORT_SwitchToPriviledgedMode:

	svc #SVC_SWITCH_TO_PRIVILEDGED_MODE
	bx lr


/* void NANO_OS_PORT_SwitchToUnpriviledgedMode(void)
   Switch the CPU to unpriviledged mode */
NANO_OS_PORT_SwitchToUnpriviledgedMode:

	movs	r0, #0x03	/* nPRIV bit = 1, active stack pointer = PSP */
	msr		control, r0

	bx lr



/* nano_os_error_t NANO_OS_PORT_FirstContextSwitchAsm(void)
   Port specific first task context switch */
NANO_OS_PORT_FirstContextSwitchAsm:

    /* Set SP=MSP to point to the reset MSP value to use initial C stack as exception stack. */
    ldr     r0, =0xE000ED08
    ldr     r0, [r0]
    ldr     r1, [r0]
    mov		sp, r1

    /* Enable interrupts */
    cpsie	i

	/* Start first context switch */
	svc		#SVC_FIRST_CONTEXT_SWITCH

	/* Return to caller (should never happen)*/
    bx      lr



/* void NANO_OS_PORT_ContextSwitchFromIsr(void)
   Port specific interrupt level context switch */
NANO_OS_PORT_ContextSwitchFromIsr:

	/* Initialize a PendSv exception to perform the context switch */
    ldr     r0, =0x10000000 /* PendSv Mask */
    ldr     r1, =0xE000ED04 /* ICSR register */
    ldr     r2, [r1]
    orrs     r2, r2, r0
    str     r2, [r1]

    /* Return to caller */
    bx      lr



.thumb_func
.type NANO_OS_PORT_ContextSwitch, %function
/* void NANO_OS_PORT_ContextSwitch(void)
   Port specific task level context switch : register saving + context switch */
NANO_OS_PORT_ContextSwitch:

    /* Initialize a PendSv exception to perform the context switch */
    ldr     r0, =0x10000000 /* PendSv Mask */
    ldr     r1, =0xE000ED04 /* ICSR register */
    ldr     r2, [r1]
    orrs     r2, r2, r0
    str     r2, [r1]

    /* Enable interrupt to perform context switch */
    cpsie   i

    /* Disable interrupt before returning to OS */
    cpsid   i

    /* Return to OS protected code */
    bx      lr


.thumb_func
.type NANO_OS_PORT_SvcHandler, %function
/* void NANO_OS_PORT_SvcHandler(void)
   Handler for the SVC exception. Performs switchs between priviledged modes */
NANO_OS_PORT_SvcHandler:

	/* Check which stack was used for SVC call */
	movs	r0, #4
	mov		r1, lr
	tst		r0, r1
	beq		NANO_OS_PORT_SvcHandler_FromMSP
	mrs 	r0, psp
	b		NANO_OS_PORT_SvcHandler_Extract_SVC_Number

NANO_OS_PORT_SvcHandler_FromMSP:
	mrs 	r0, msp

NANO_OS_PORT_SvcHandler_Extract_SVC_Number:
	/* Extract SVC number */
	ldr		r0, [r0, #24]
	subs	r0, r0, #2
	ldrb	r0, [r0]

	/* Branch to corresponding handler */
	movs	r1, SVC_FIRST_CONTEXT_SWITCH
	cmp		r0, r1
	beq		NANO_OS_PORT_SvcHandler_FirstContextSwitch
	movs	r1, SVC_SWITCH_TO_PRIVILEDGED_MODE
	cmp		r0, r1
	beq		NANO_OS_PORT_SvcHandler_SwitchToPriviledgedMode

NANO_OS_PORT_SvcHandler_FirstContextSwitch:
	/* First context switch */

	/* Get the stack pointer of the next task */
    ldr     r0, =g_nano_os
    ldr     r1, [r0, #4]
    ldr     r2, [r1]

    /* g_nano_os.current_task = g_nano_os.next_running_task */
    str     r1, [r0]

    /* Reset MSP */
    mov		r0, sp
	adds	r0, r0, #0x20
    mov		r12, r0

	/* Configure task specific MPU regions */
    mov		r0, r1
    push	{r2}
    bl		NANO_OS_PORT_MPU_ConfigureTaskSpecificRegions
    pop		{r2}

	/* Restore the control register from the next task stack */
	mov		sp, r2
	pop		{r2}
	msr		control, r2

	/* Restore the additionnals registers from the next task stack */
    pop     {r4-r7}
    mov     r8, r4
    mov     r9, r5
    mov     r10, r6
    mov     r11, r7
    pop     {r4-r7}
    mov		r2, sp
    msr		psp, r2

    /* Restore MSP */
    mov		sp, r12

	/* Exit exception and configure CPU to use PSP for task's stack pointers */
	ldr		r0, =0xFFFFFFFD
    bx      r0

NANO_OS_PORT_SvcHandler_SwitchToPriviledgedMode:
	/* Switch the CPU to priviledged mode */
	movs	r0, #0x00	/* nPRIV bit = 0 */
	msr		control, r0

	/* Exit exception */
    bx      lr


/* void NANO_OS_PORT_PendSvHandler()
   Handler for the PendSv exception. Performs context switchs */
NANO_OS_PORT_PendSvHandler:

    /* Disable interrupts */
    cpsid   i

    /* Save MSP */
    mov		r12, sp

    /* Save the additionnals registers to the current task stack */
    mrs		r0, psp
    mov		sp, r0
    push    {r4-r7}
    mov     r4, r8
    mov     r5, r9
    mov     r6, r10
    mov     r7, r11
    push    {r4-r7}

    /* Save control register */
    mrs		r4, control
    push	{r4}

    /* Get the stack pointer of the next task */
    ldr     r0, =g_nano_os
    ldr     r1, [r0, #4]
    ldr     r2, [r1]

    /* Save the stack pointer for the current task */
    ldr     r3, [r0]
    mov		r4, sp
    str     r4, [r3]

    /* Set the stack pointer to the next task */
    mov     sp, r2

    /* g_nano_os.current_task = g_nano_os.next_running_task */
    str     r1, [r0]

    /* Re-configure task specific MPU regions */
    mov		r0, r1
    mov		r11, lr
    bl		NANO_OS_PORT_MPU_ConfigureTaskSpecificRegions
	mov		lr, r11

	/* Restore the control register from the next task stack */
	pop		{r4}
	msr		control, r4

    /* Restore the additionnals registers from the next task stack */
    pop     {r4-r7}
    mov     r8, r4
    mov     r9, r5
    mov     r10, r6
    mov     r11, r7
    pop     {r4-r7}
    mov		r0, sp
    msr		psp, r0

	/* Restore MSP */
    mov		sp, r12

    /* Enable interrupts */
    cpsie   i

    /* Exit exception */
    bx      lr



/* void NANO_OS_PORT_MPU_ConfigureTaskSpecificRegions(nano_os_task_t* current_task)
   Configure the task specific MPU regions */
NANO_OS_PORT_MPU_ConfigureTaskSpecificRegions:

	/* Disable MPU */
	ldr		r1, =MPU_CTRL_REG
	ldr		r2, [r1]
	ldr		r3, =0xFFFFFFFE
	ands	r3, r2
	str		r3, [r1]

	/* Load new MPU regions configuration */
	adds	r0, r0, #4
	push  	{r1}
	mov		r1, sp
	mov		sp, r0
	pop		{r3 - r6}

	/* Store MPU configuration */
	ldr		r0, =MPU_RBAR_REG
	str		r4, [r0]
	str		r3, [r0, #4]
	str		r6, [r0]
	str		r5, [r0, #4]

	pop		{r3 - r6}
	str		r4, [r0]
	str		r3, [r0, #4]
	str		r6, [r0]
	str		r5, [r0, #4]

	/* Enable MPU */
	mov		sp, r1
	pop		{r1}
	str		r2, [r1]
	dsb
	isb

	/* Return to caller */
	bx		lr

    END
