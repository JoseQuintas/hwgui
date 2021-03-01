/*
 * alert() replacement.
 *
 * Copyright 2005,2020 Alex Strickland <sscc@mweb.co.za>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, you have permission for
 * additional uses of the text contained in its release of HWGUI.
 *
 * The exception is that, if you link the HWGUI library with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the HWGUI library code into it.
 */

#ifndef IDI_APPLICATION
#define IDI_APPLICATION         32512
#define IDI_HAND                32513
#define IDI_QUESTION            32514
#define IDI_EXCLAMATION         32515
#define IDI_ASTERISK            32516
#define IDI_WINLOGO             32517
#define IDI_INFORMATION         IDI_ASTERISK
#define IDI_WARNING             IDI_EXCLAMATION
#define IDI_ERROR               IDI_HAND
#endif

    // -1 uses the speaker instead of the sound card
#ifndef MB_OK
#define MB_OK                   0
#define MB_ICONHAND             16
#define MB_ICONQUESTION         32
#define MB_ICONEXCLAMATION      48
#define MB_ICONASTERISK         64
#endif

#define ALERT_MODAL             .t.
#define ALERT_NOTMODAL          .f.

#define ALERT_BEEP              .t.
#define ALERT_NOBEEP            .f.

#define ALERT_TITLEICON         .t.
#define ALERT_NOTITLEICON       .f.

#define ALERT_CLOSEBUTTON       .t.
#define ALERT_NOCLOSEBUTTON     .f.

