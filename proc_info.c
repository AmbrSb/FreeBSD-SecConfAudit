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


#define SAFE    (0)
#define UNSAFE  (1)
#define FAILURE (2)

typedef int safety_t;

/**
 * Checks whether process with pid `pid` is running in Capsicum
 * capability mode.
 */
safety_t check_capmode(pid_t pid)
{
	int capmode;
	struct kinfo_proc *kp;

	kp = kinfo_getproc(pid);
	if (!kp)
		return (FAILURE);
	if (kp->ki_cr_flags & CRED_FLAG_CAPMODE)
		capmode = SAFE;
	else
		capmode = UNSAFE;
	free(kp);

	return (capmode);
}

/**
 * Checks whether process with pid `pid` is running as setuid
 */
safety_t check_setuid(pid_t pid)
{
	int setuid;
	uid_t efu, reu, svu;
	struct kinfo_proc *kp;

	kp = kinfo_getproc(pid);
	if (!kp)
		return (FAILURE);
	efu = kp->ki_uid;
	reu = kp->ki_ruid;
	svu = kp->ki_svuid;
	free(kp);
	if (efu != reu || reu !=svu)
		setuid = UNSAFE;
	else
		setuid = SAFE;

	return (setuid);
}

/**
 * Checks whether the process with pid `pid` is running in jail
 * other than jail #0
 */
safety_t check_jailed(pid_t pid)
{
	int jid;
	struct kinfo_proc *kp;

	kp = kinfo_getproc(pid);
	if (!kp)
		return (FAILURE);
	jid = kp->ki_jid;
	free(kp);

	if (jid != 0)
		return (SAFE);
	else
		return (UNSAFE);
}

int main(int argc, char *argv[])
{
	pid_t pid;

	if (argc != 2)
		return (1);
	pid = strtoul(argv[1], NULL, 10);
	if (pid == 0)
		return (2);

	printf("%d", check_capmode(pid));
	printf(" %d", check_setuid(pid));
	printf(" %d", check_jailed(pid));

	return (0);
}

