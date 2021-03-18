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


RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m'

fieldspacing=4

error()
{
	printf "${PURPLE}$1${NC}\n"
	exit 1;
}

print_field()
{
	strlen=`echo -n $1 | wc -m`
	fieldsz=`expr $strlen + ${fieldspacing}`
	if [ $2 == "na" ]; then
		printf "%$-${fieldsz}s" "-"
	elif [ $2 -eq "0" ]; then
		positive "$1" N
	elif [ $2 -eq "1" ]; then
		negative "$1" N
	fi
}

positive()
{
	strlen=`echo -n $1 | wc -m`
	fieldsz=`expr $strlen + ${fieldspacing}`
	if [ "$2" == "N" ]; then
		printf "${GREEN}%-${fieldsz}s${NC}" "$1"
	else
		printf "${GREEN}[YES] ${NC}%-${fieldsz}s\n" "$1"
	fi
}

negative()
{
	strlen=`echo -n $1 | wc -m`
	fieldsz=`expr $strlen + ${fieldspacing}`
	if [ "$2" == "N" ]; then
		printf "${RED}%-${fieldsz}s${NC}" "$1"
	else
		printf "${RED}[NO]  ${NC}%-${fieldsz}s\n" "$1"
	fi
}

check_result()
{
	test "$2" -eq 0 && positive "$1" || negative "$1"
}

check_sysctl()
{
	if [ "$2" = "CHECK" ]; then
		sysctl -q $1 > /dev/null
	elif [ "$2" = "CONTAINS" ]; then
		sysctl -n $1 | grep $3 > /dev/null
	elif [ "$2" = "GT" ]; then
		test `sysctl -n $1` -gt $3 > /dev/null
	else
		test "`sysctl -qn $1`" = "$2"
	fi
}
