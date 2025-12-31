Requires to have a alpine (or similar) template running. It should have an enabled SSH service.

# My setup
Initially, I was going for a simple Alpine based build. The plan was to have alpine with SSH server enabled and nixos-anywhere connecting to it and deploying NixOS.
Unfortunately, Alpine was "too hardened" for that usecase as kexec syscall is disabled in the default kernel. So I was moving to another solution.

Instead I created a flake that allows easy installation of a simple NixOS that can then be used as template.
To do so, just boot a NixOS installation ISO in a fresh VM, download this directory and run:

```
sudo nix --extra-experimental-features nix-command --extra-experimental-features flakes  run github:nix-community/disko -- --mode disko --flake .#bootstrap
sudo nixos-install --flake .#bootstrap --no-root-password
```

Afterwards, shutdown the VM and detach the ISO from it. Then add a CloudInit Drive (Hardware -> CloudInit Drive).


Your setup should look like that:
```
root@pve-t2-01:~# qm config 116
bios: seabios
boot: order=scsi0;ide2
cipassword: **********
ciuser: ***
cores: 4
ide2: local-lvm:vm-116-cloudinit,media=cdrom
machine: q35
memory: 9024
meta: creation-qemu=9.0.2,ctime=1767050251
name: Copy-of-VM-nixos-bootstrap
net0: virtio=BC:24:11:BE:20:2F,bridge=vmbr0
numa: 0
scsi0: local-lvm:vm-116-disk-0,iothread=1,size=6G
scsihw: virtio-scsi-single
serial0: socket
smbios1: uuid=00dc7544-1625-484d-8364-6ff05646f5ef
sockets: 1
sshkeys: ***```

Add your SSH public key, the username and click "Regenerate Image". Power on the VM and try logging into the VM. If it works, clean cloud-init and create a template.

In VM:
```
sudo cloud-init clean
sudo rm -rf /var/lib/cloud/*
sudo rm /home/admin/.ssh/authorized_keys
sudo poweroff
```

On PVM:
```
qm template 116
```

Then you are ready to continue with the terraform provider. Just note down the template ID and set it accordingly in TF.
