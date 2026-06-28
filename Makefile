TARGET = maya22-control
SRC = maya22-control.c
CXX = g++
CXXFLAGS = -std=c++11 -O3
LDFLAGS = -lhidapi-hidraw -lhidapi-libusb
UDEV_RULES = /etc/udev/rules.d/50-esi-maya22.rules

.PHONY: all clean install uninstall

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) -o $(TARGET) $(LDFLAGS)
	strip $(TARGET)

clean:
	rm -f $(TARGET)

install: $(TARGET)
	install -m 755 $(TARGET) /usr/local/bin/$(TARGET)
	@echo "Creating udev rule..."
	@echo 'KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2573", ATTRS{idProduct}=="0017", GROUP="plugdev", MODE="0660", RUN+="/usr/local/bin/$(TARGET) -d"' | sudo tee $(UDEV_RULES) > /dev/null
	@echo "Reloading udev..."
	sudo udevadm control --reload-rules && sudo udevadm trigger
	@echo "Installed. Unplug and re-plug the device."

uninstall:
	sudo rm -f /usr/local/bin/$(TARGET)
	sudo rm -f $(UDEV_RULES)
	sudo udevadm control --reload-rules
