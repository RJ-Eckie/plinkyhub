# plinkyhub

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## WebUSB on Linux

If you get a `SecurityError: Failed to execute 'open' on 'USBDevice': Access denied`
error when trying to connect to Plinky, you need to grant your user permission to
access the USB device.

1. **Verify Plinky is connected** by running `lsusb`. You should see something like:
   ```
   Bus 001 Device 026: ID cafe:4018 Plinky PlinkySynth MIDI
   ```

2. **Add your user to the `plugdev` group:**
   ```bash
   sudo usermod -a -G plugdev $USER
   ```
   Log out and back in for the change to take effect. Verify with the `groups` command.

3. **Create a udev rule:**
   ```bash
   sudo nano /etc/udev/rules.d/99-plinky.rules
   ```
   Add the following line:
   ```
   SUBSYSTEM=="usb", ATTRS{idVendor}=="cafe", MODE="0660", GROUP="plugdev"
   ```

4. **Reload udev rules:**
   ```bash
   sudo udevadm control --reload-rules
   ```

5. **Reconnect Plinky** by unplugging and replugging the USB cable.
