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

#ifndef PIT_H
#define PIT_H

#include "nano_os_user.h"


#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */


/** \brief Initialize the PIT timer */
void PIT_Init(const fp_nano_os_system_timer_callback_func_t system_timer_irq_callback);

/** \brief Start the PIT timer */
void PIT_Start();

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* PIT_H */
