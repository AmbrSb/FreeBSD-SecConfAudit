# FreeBSD-SecConfAudit

This project provides a set of scripts/programs that run various security/sanity checks on a running FreeBSD machine and report the results.
This is still a work in progress and I am adding new checks and improving existing ones. These audit checks are based on disecting binary files, system calls, sysctl probes, etc.

## Types of Audit Checks
- Global system configuration checks
- Process checks
- Executable checks
- Library checks

## Screenshots
- Global system config checks
![image](https://user-images.githubusercontent.com/19773760/111761840-967a7d00-88b5-11eb-8c1c-d354609f09ab.png)

- Process checks
These info are extracted either from the ELF file, or directly from the kernel through kinfo_getproc() system call.
![image](https://user-images.githubusercontent.com/19773760/111784641-e155be00-88d0-11eb-922a-c3a25ba30b7e.png)


## Prequisits
- pax-utils > 1.2.2
- lscpu > 1.2.0
- cmake >= 3.5
