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

#ifndef NANO_OS_CONSOLE_H
#define NANO_OS_CONSOLE_H

#include "nano_os_types.h"

/* Check if module is enabled */
#if (NANO_OS_CONSOLE_ENABLED == 1u)

#include "nano_os_port.h"


#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */


/** \brief Prototype of functions which will handle the console commands */
typedef void (*fp_nano_os_console_cmd_handler_t)(void* const user_data, const uint32_t command_id, const char* const params);

/** \brief Console command description */
typedef struct _nano_os_console_cmd_desc_t
{
    /** \brief Name */
    const char* name;
    /** \brief Help string */
    const char* help;
    /** \brief Handler */
    fp_nano_os_console_cmd_handler_t handler;
} nano_os_console_cmd_desc_t;

/** \brief Console command group description */
typedef struct _nano_os_console_cmd_group_desc_t
{
    /** \brief Commands */
    const nano_os_console_cmd_desc_t* commands;
    /** \brief Number of commands */
    uint32_t command_count;
    /** \brief User data */
    void* user_data;

    /** \brief Next command group */
    struct _nano_os_console_cmd_group_desc_t* next;
} nano_os_console_cmd_group_desc_t;



/** \brief Initialize the console module */
nano_os_error_t NANO_OS_CONSOLE_Init(const nano_os_port_init_data_t* const port_init_data);

/** \brief Register commands to the console module */
nano_os_error_t NANO_OS_CONSOLE_RegisterCommands(nano_os_console_cmd_group_desc_t* const commands);

/** \brief Get the next parameter in the command line */
const char* NANO_OS_CONSOLE_GetNextParam(const char* const current_param);



#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* (NANO_OS_CONSOLE_ENABLED == 1u) */

#endif /* NANO_OS_CONSOLE_H */
