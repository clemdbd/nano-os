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


#ifndef TASKS_H
#define TASKS_H

#include "nano_os_api.h"


/** \brief Task synchronization semaphore */
extern nano_os_semaphore_t g_synchro_sem;

/** \brief Private data from main task */
extern uint32_t g_main_task_private_data;

/** \brief Private data from led task */
extern uint32_t g_led_task_private_data;


#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */


/** \brief Create main task */
nano_os_error_t MAIN_TASK_Init(void);

/** \brief Create LED task */
nano_os_error_t LED_TASK_Init(void);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* TASKS_H */
