---
title: fix "no sound" issue under manjaro
date: 2019-12-31 21:11:33
updated: 2020-03-29 15:44:51
tags:
- linux
- sound
---

Recently I installed the *manjaro* linux.

However it could not detect my *Intel* sound card automatically.

<!--more-->

Here some logs showing in *dmesg*:

```
kernel: sof-audio-pci 0000:00:1f.3: warning: No matching ASoC machine driver found
kernel: sof-audio-pci 0000:00:1f.3: DSP detected with PCI class/subclass/prog-if 0x040380
kernel: sof-audio-pci 0000:00:1f.3: use msi interrupt mode
kernel: sof-audio-pci 0000:00:1f.3: bound 0000:00:02.0 (ops i915_audio_component_bind_ops [i915])
kernel: sof-audio-pci 0000:00:1f.3: hda codecs found, mask 5
kernel: sof-audio-pci 0000:00:1f.3: using HDA machine driver skl_hda_dsp_generic now
kernel: sof-audio-pci 0000:00:1f.3: Direct firmware load for intel/sof/sof-cnl.ri failed with error -2
kernel: sof-audio-pci 0000:00:1f.3: error: request firmware intel/sof/sof-cnl.ri failed err: -2
kernel: sof-audio-pci 0000:00:1f.3: error: failed to load DSP firmware -2
kernel: sof-audio-pci 0000:00:1f.3: error: sof_probe_work failed err: -2
```

After searching online, I found a [same issue](https://bugs.archlinux.org/task/64720) in the bug list of *Arch Linux*.

It gives us a solution.

Just add a file in /etc/modprobe.d/ with its content as below:

```
options snd_hda_intel dmic_detect=0
```

And then reboot your computer.

Or

Simply switch your kernel to `4.19` will solve this problem.