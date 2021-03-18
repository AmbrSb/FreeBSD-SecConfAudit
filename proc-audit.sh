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

# prequisite packages: pax-utils (for scanelf), procstat

check_process()
{
	elfexec=$1
	pid=$2

	# Running in capability mode
	ps "$pid" >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		info=`./proc_info $pid`
		capability_mode=`echo $info | awk '{print $1}'`
		setuid=`echo $info | awk '{print $2}'`
		jid=`echo $info | awk '{print $3}'`
	else
		capability_mode="na"
		setuid="na"
	fi

	# relocation readonly
	# check for presence of GNU_RELRO program header
	# Full/Partial RELRO
	readelf -l ${elfexec} | grep -w "GNU_RELRO" > /dev/null
	relro=$?
	readelf -d ${elfexec} | grep -w "FLAGS" | grep -w "BIND_NOW" > /dev/null
	bindnow=$?

	# If you compile assembly code, gcc will not automatically add GNU_STACK markings.
	# So, the most common source of executable stacks in ELF binaries are packages which
	# include raw assembly code. Note that we're not talking about inline assembly code,
	# but rather files like .S which are written in pure assembler.

	# check for ProPolice stack protection
	readelf -s ${elfexec} | grep -w "FUNC" | grep -w "UND" | grep "__stack_chk_fail" > /dev/null
	propolic=$?

	# Executable stack
	# -Wl,-z,noexecstack -Wa,--noexecstack
	# -Wl,-z,execstack
	readelf -e ${elfexec} | grep -A1 -w "GNU_STACK" | tail -n 1 | grep -v -w "RWE" > /dev/null
	nxstack=$?

	# PIE
	# search in relocation section with r_type R_X86_64_RELATIVE
	readelf -r ${elfexec} | grep "Elf file type is DYN" > /dev/null
	readelf -r ${elfexec} | egrep "R_.*_RELATIVE" > /dev/null
	pie=$?

	# CFI clang control flow integrity
	# -fsanitize-cfi-icall-generalize-pointers
	# -fsanitize-cfi-canonical-jump-tables
	# -fsanitize=cfi-icall and -fsanitize=function
	readelf -s ${elfexec} | egrep "__ubsan_.*_cfi" > /dev/null
	cfi=$?

	# SafeStack
	readelf -s ${elfexec} | grep "__safestack_init" > /dev/null
	safestack=$?

	# Check if RUNPATH RPATH of running processes are set to directories writable
	# by non-root users.
	runpaths=`readelf -d ${elfexec} | grep RUNPATH | awk '{print $5}' | cut -c 2- | rev | cut -c 2- | rev`
	wrpath=0
	if [ $? -eq 0 ]; then
		for dir in `echo $runpaths | tr ":" "\n"`; do
			ls -ald ${dir} | awk '{print $1}' | cut -c 5- | grep -v w >/dev/null 2>&1
			wrpath=$?
			if [ $wrpath -eq 1 ]; then
				break
			fi

			ls -ald ${dir} | awk '{print $3}' | grep root >/dev/null 2>&1
			wrpath=$?
			if [ $wrpath -eq 1 ]; then
				break
			fi
		done
	fi

	# Print out the result of above checks
	printf "%-16s%-8s" `basename "${elfexec}"` "${pid}"
	print_field "CapabilityMode" $capability_mode
	print_field "writeableRPATH" $wrpath
	print_field "SetUID" $setuid
	print_field "Jailed" $jid
	print_field "RelRO" $relro
	print_field "BindNow" $bindnow
	print_field "ProPolice" $propolic
	print_field "SafeStack" $safestack
	print_field "NXStack" $nxstack
	print_field "PIE" $pie
	echo
}

# Find all pids of running processes
pids=`procstat -ab | awk '{print $1}' | tail -n +2 | sort | uniq`
for pid in $pids; do
	path=`procstat -b $pid 2>/dev/null | tail -n +2 | awk '{print $4}'`
	if [ -f "$path" ]; then
		check_process ${path} ${pid}
	fi
done

