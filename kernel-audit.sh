#! /bin/sh

# BSD 2-Clause License
# 
# Copyright (c) 2021, Amin Saba
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


. common.sh
. /etc/rc.subr

KERN_PATH=`sysctl -qn kern.bootfile`
if [ -z $KERN_PATH ]; then
	error "Cannot determine path to the running kernel!"
fi

feature="Kernel secure level set"
check_sysctl "kern.securelevel" GT 0
check_result "$feature" $?

feature="Processes with uid 0 are unprivilleged"
check_sysctl "security.bsd.suser_enabled" 0
check_result "$feature" $?

feature="Unprivileged users may not mount and unmount file systems"
check_sysctl "vfs.usermount" 0
check_result "$feature" $?

feature="Kernel MAC support"
check_sysctl "kern.features.security_mac" 1
check_result "$feature" $?

# TODO check MAC/modules configuration
feature="Any MAC module loaded"
kldstat | grep mac_ > /dev/null 2>&1
check_result "$feature" $?

feature="MAC mmap revocation enabled"
check_sysctl "security.mac.mmap_revocation" 1
check_result "$feature" $?

feature="Kernel capability mode support"
check_sysctl "kern.features.security_capability_mode" 1
check_result "$feature" $?

feature="ASLR enabled for ELF64"
check_sysctl "kern.elf64.aslr.enable" 1
check_result "$feature" $?

feature="PIE enabled for ELF64"
check_sysctl "kern.elf64.aslr.pie_enable" 1
check_result "$feature" $?

feature="ASLR enabled for ELF32"
check_sysctl "kern.elf32.aslr.enable" 1
check_result "$feature" $?

feature="PIE enabled for ELF32"
check_sysctl "kern.elf32.aslr.pie_enable" 1
check_result "$feature" $?

feature="Core dump disabled"
check_sysctl "kern.coredump" 0
check_result "$feature" $?

feature="Core dump disabled in capability mode"
check_sysctl "kern.capmode_coredump" 0
check_result "$feature" $?

feature="Core dump disabled for setuid/setgid programs"
check_sysctl "kern.sugid_coredump" 1
check_result "$feature" $?

feature="NODUMP flag on core dump files enabled"
check_sysctl "kern.nodump_coredump" 1
check_result "$feature" $?

feature="Kernel supports dump encryption"
check_sysctl "kern.conftxt" CONTAINS EKCD
check_result "$feature" $?

feature="Kernel dump encryption configured (according to rc.conf)"
load_rc_config_var _ dumpon_flags
echo $dumpon_flags | egrep "\-k.+" >/dev/null 2>&1
check_result "$feature" $?

feature="CPU supports executable space protection (XD/NX)"
if [ -x `which lscpu` ]; then
	lscpu | grep -w "Flags:" | grep -w "nx" > /dev/null
else
	dmesg | grep -w "AMD Features" | grep -w "NX" > /dev/null
fi
check_result "$feature" $?

feature="None-executable stack for 32-bit ELF executables"
check_sysctl "kern.elf32.nxstack" 1
check_result "$feature" $?

feature="None-executable stack for 64-bit ELF executables"
check_sysctl "kern.elf64.nxstack" 1
check_result "$feature" $?

feature="Capability mode support (Capsicum)"
check_sysctl "kern.conftxt" CONTAINS CAPABILITY_MODE
check_result "$feature" $?

feature="KTrace disabled"
check_sysctl "kern.features.ktrace" 0
check_result "$feature" $?

feature="Audit support"
check_sysctl "kern.features.audit" 1
check_result "$feature" $?

feature="Audit service enabled"
service -e | grep -w auditd
check_result "$feature" $?

feature="Audit trail files distribution service enabled"
service -e | grep auditdistd
check_result "$feature" $?

feature="Unprivileged processes not allowed to debug"
check_sysctl "security.bsd.unprivileged_proc_debug" 0
check_result "$feature" $?

feature="Non-root users cannot call mlock"
check_sysctl "security.bsd.unprivileged_mlock" 0
check_result "$feature" $?

feature="Unprivileged processes may not read the kernel message buffer"
check_sysctl "security.bsd.unprivileged_read_msgbuf" 0
check_result "$feature" $?

feature="Non-root users may not set an idle priority"
check_sysctl "security.bsd.unprivileged_idprio" 0
check_result "$feature" $?

feature="Unprivileged processes may not retrieve quotas for other uids/gids"
check_sysctl "security.bsd.unprivileged_get_quota" 0
check_result "$feature" $?

feature="Secure hardlinks"
check_sysctl "security.bsd.hardlink_check_uid" 1 &&
check_sysctl "security.bsd.hardlink_check_gid" 1
check_result "$feature" $?

feature="Conservative signals"
check_sysctl "security.bsd.conservative_signals" 1
check_result "$feature" $?

feature="Unprivileged may not see other UIDs/GIDs"
check_sysctl "security.bsd.see_other_gids" 0 &&
check_sysctl "security.bsd.see_other_uids" 0
check_result "$feature" $?

feature="Unprivileged may not see proccesses in other jails"
check_sysctl "security.bsd.see_jail_proc" 0
check_result "$feature" $?

feature="Non-root processes cannot read DIRs"
check_sysctl "security.bsd.allow_read_dir" 0
check_result "$feature" $?

feature="Disallow map at 0 address"
check_sysctl "security.bsd.map_at_zero" 0
check_result "$feature" $?

feature="Kernel compiled with REDZONE"
check_sysctl "vm.redzone" CHECK
check_result "$feature" $?

feature="Kernel compiled with MEMGUARD"
check_sysctl "vm.memguard" CHECK
check_result "$feature" $?

feature="Randomized PID"
check_sysctl "kern.randompid" GT 0
check_result "$feature" $?

feature="Randomized portrange"
check_sysctl "net.inet.ip.portrange.randomized" 1
check_result "$feature" $?

