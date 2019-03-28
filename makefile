
cc = clang
cflags = -I efi -target x86_64-pc-win32-coff -fno-stack-protector -fshort-wchar -mno-red-zone
ld = lld-link
lflags = -subsystem:efi_application -nodefaultlib -dll

original_ovmf_code = /usr/share/ovmf/x64/OVMF_CODE.fd
original_ovmf_vars = /usr/share/ovmf/x64/OVMF_VARS.fd
boot = image/EFI/BOOT

all : hello-c.efi hello-fasm.efi memmap.efi

hello-fasm.efi : hello-fasm.obj
	$(ld) $(lflags) -entry:efi_main $< -out:$@
	cp $@ $(boot)/

hello-c.efi : hello-c.obj
	$(ld) $(lflags) -entry:efi_main $< -out:$@
	cp $@ $(boot)/

memmap.efi : memmap.obj
	$(ld) $(lflags) -entry:efi_main $< -out:$@
	cp hello-c.efi $(boot)/
	cp $@ $(boot)/

hello-fasm.obj : hello-fasm.asm
	fasm $<

hello-c.obj : hello-c.c
	$(cc) $(cflags) -c $< -o $@

memmap.obj : memmap.c
	$(cc) $(cflags) -c $< -o $@

OVMF_CODE.fd:
	cp $(original_ovmf_code) $@

OVMF_VARS.fd:
	cp $(original_ovmf_vars) $@

# See https://osdev-jp.readthedocs.io/ja/latest/2017/create-uefi-app-with-edk2.html
# 1. `make run`
# 2. Press F2 repeatedly and show boot menu
# 3. Select EFI Internal Shell
# 4. fs0: ... (same as REAME)
run: all OVMF_CODE.fd OVMF_VARS.fd
	qemu-system-x86_64 \
		-drive if=pflash,format=raw,readonly,file=OVMF_CODE.fd \
		-drive if=pflash,format=raw,file=OVMF_VARS.fd \
		-drive if=ide,file=fat:rw:image,index=0,media=disk

.PHONY : clean
clean:
	if ls *.lib 1> /dev/null 2>&1 ; then rm *.lib ; fi
	if ls *.dll 1> /dev/null 2>&1 ; then rm *.dll ; fi
	if ls *.efi 1> /dev/null 2>&1 ; then rm *.efi ; fi
	if ls *.exe 1> /dev/null 2>&1 ; then rm *.exe ; fi
	if ls *.obj 1> /dev/null 2>&1 ; then rm *.obj ; fi
	rm -f OVMF_VARS.fd
	rm -f OVMF_CODE.fd
	rm -f $(boot)/*
