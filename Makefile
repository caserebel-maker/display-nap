APP_NAME = DisplayNap
BUILD_DIR = build

.PHONY: all build install run clean

all: build

build:
	@chmod +x build.sh
	@./build.sh

install: build
	@chmod +x install.sh
	@./install.sh

run: build
	@open "$(BUILD_DIR)/$(APP_NAME).app"

clean:
	@rm -rf $(BUILD_DIR)
