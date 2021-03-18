/*
 * BSD 2-Clause License
 * 
 * Copyright (c) 2021, Amin Saba
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <sys/types.h>
#include <sys/user.h>
#include <libutil.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ucred.h>


int main(int argc, char *argv[])
{
	int capmode = 1;
	int setuid = 0;
	pid_t pid;
	uid_t efu, reu, svu;
	int jid;

	if (argc != 2)
		return (1);

	pid = strtoul(argv[1], NULL, 10);
	struct kinfo_proc *kp = kinfo_getproc(pid);
	if (!kp)
		return (2);
	if (kp->ki_cr_flags & CRED_FLAG_CAPMODE)
		capmode = 0;
	printf("%d", capmode);

	efu = kp->ki_uid;
	reu = kp->ki_ruid;
	svu = kp->ki_svuid;
	if (efu != reu || reu !=svu)
		setuid = 1;
	printf(" %d", setuid);

	jid = kp->ki_jid;
	if (jid == 0)
		printf(" %d", 1);
	else
		printf(" %d", 0);

	return (0);
}

