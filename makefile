# ========================
# Project configuration
# ========================
TARGET_BASE := main
CC  := gcc
CXX := g++
SRC_DIR := src
OBJ_BASE_DIR := obj

# Add your custom libraries here (e.g., -lm -lpthread)
CUSTOM_LIBS :=

# ========================
# Language standard selection
# ========================
C_STD   ?= c11
CXX_STD ?= c++17

# ========================
# Configurable compiler flags (true/false)
# ========================
WALL      := $(or $(WALL),true)
WERROR    := $(or $(WERROR),true)
WEXTRA    := $(or $(WEXTRA),true)
WPEDANTIC := $(or $(WPEDANTIC),false)
WSHADOW   := $(or $(WSHADOW),false)

# Build warning flags
WARNING_FLAGS := $(if $(filter true,$(WALL)),-Wall) \
                 $(if $(filter true,$(WERROR)),-Werror) \
                 $(if $(filter true,$(WEXTRA)),-Wextra) \
                 $(if $(filter true,$(WPEDANTIC)),-Wpedantic) \
                 $(if $(filter true,$(WSHADOW)),-Wshadow)

# Standard flags
STD_FLAGS := -std=$(C_STD)
CXX_STD_FLAGS := -std=$(CXX_STD)

# ========================
# OS detection
# ========================
ifeq ($(OS),Windows_NT)
    PLATFORM := Windows
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        PLATFORM := Linux
    else ifeq ($(UNAME_S),Darwin)
        PLATFORM := macOS
    else
        PLATFORM := Unknown
    endif
endif
ifeq ($(PLATFORM),Unknown)
$(error Unsupported platform: $(UNAME_S))
endif

# ========================
# Build mode default
# ========================
MODE ?= release
OBJ_DIR := $(OBJ_BASE_DIR)/$(PLATFORM)/$(MODE)

# ========================
# OS-specific commands
# ========================
ifeq ($(PLATFORM),Windows)
    TARGET := $(TARGET_BASE).exe
    MKDIR_CMD  = if not exist "$(OBJ_DIR)" mkdir "$(OBJ_DIR)"
    RMEXE_CMD  = if exist "$(TARGET)" del /q "$(TARGET)"
    RUN_CMD    = "$(CURDIR)/$(TARGET)"
    BLANK_CMD  = echo.
else
    TARGET := $(TARGET_BASE)
    MKDIR_CMD  = mkdir -p "$(OBJ_DIR)"
    RMEXE_CMD  = rm -f "$(TARGET)"
    RUN_CMD    = "$(CURDIR)/$(TARGET)"
    BLANK_CMD  = echo
endif

# ========================
# Include + libraries
# ========================
INCLUDES := -I"$(CURDIR)/include"
LDFLAGS  := $(CUSTOM_LIBS)

# ========================
# Build mode flags
# ========================
ifeq ($(MODE),debug)
    CFLAGS   := $(STD_FLAGS) $(WARNING_FLAGS) -Og -g -D_DEBUG
    CXXFLAGS := $(CXX_STD_FLAGS) $(WARNING_FLAGS) -Og -g -D_DEBUG
endif
ifeq ($(MODE),release)
    CFLAGS   := $(STD_FLAGS) $(WARNING_FLAGS) -O2 -DNDEBUG
    CXXFLAGS := $(CXX_STD_FLAGS) $(WARNING_FLAGS) -O2 -DNDEBUG
endif

# ========================
# Source discovery
# ========================
C_SOURCES   := $(wildcard $(SRC_DIR)/*.c)
CPP_SOURCES := $(wildcard $(SRC_DIR)/*.cpp)
C_OBJECTS   := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(C_SOURCES))
CPP_OBJECTS := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(CPP_SOURCES))
OBJECTS := $(C_OBJECTS) $(CPP_OBJECTS)

# Use C++ linker if any C++ files exist
ifeq ($(strip $(CPP_SOURCES)),)
    LINKER := $(CC)
else
    LINKER := $(CXX)
endif

.PHONY: all build debug release run clean clean-output help info purge

# ========================
# Targets
# ========================
all: build

build: build-info $(TARGET)

debug:
	@$(MAKE) MODE=debug build

release:
	@$(MAKE) MODE=release build

run: build
	@$(BLANK_CMD)
	@echo Running $(TARGET)...
	@$(RUN_CMD)

debug-run: debug
	@$(BLANK_CMD)
	@echo Running debug $(TARGET)...
	@$(RUN_CMD)

info:
	@$(BLANK_CMD)
	@echo ============================
	@echo Platform: $(PLATFORM)
	@echo C Standard: $(C_STD)
	@echo C++ Standard: $(CXX_STD)
	@echo Warning Flags: $(WARNING_FLAGS)
	@echo ============================

build-info:
	@$(BLANK_CMD)
	@echo ============================
	@echo Build Mode: $(MODE)
	@echo Platform: $(PLATFORM)
	@echo C Standard: $(C_STD)
	@echo C++ Standard: $(CXX_STD)
	@echo Warning Flags: $(WARNING_FLAGS)
	@echo Object Dir: $(OBJ_DIR)
	@echo ============================

$(TARGET): $(OBJECTS)
	@$(BLANK_CMD)
	@echo Linking...
	$(LINKER) $(OBJECTS) $(LDFLAGS) -o "$(TARGET)"

# ========================
# Compile rules
# ========================
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	@echo Compiling C $< ...
	$(CC) $(CFLAGS) $(INCLUDES) -c "$<" -o "$@"

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp | $(OBJ_DIR)
	@echo Compiling C++ $< ...
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c "$<" -o "$@"

$(OBJ_DIR):
	@$(MKDIR_CMD)

# ========================
# Cleanup
# ========================
clean:
	@echo "Cleaning build artifacts for $(PLATFORM)..."
ifeq ($(PLATFORM),Windows)
	@if exist "$(OBJ_BASE_DIR)\$(PLATFORM)" rmdir /s /q "$(OBJ_BASE_DIR)\$(PLATFORM)" 2>nul
	@ if exist "$(OBJ_BASE_DIR)" ( \
        dir /b /a-d "$(OBJ_BASE_DIR)" 2>nul | findstr . >nul || \
        rmdir /q "$(OBJ_BASE_DIR)" 2>nul \
      )
	@ if exist "$(TARGET)" del /q /f "$(TARGET)" 2>nul
else
	@ rm -rf "$(OBJ_BASE_DIR)/$(PLATFORM)" 2>/dev/null
	@ rmdir "$(OBJ_BASE_DIR)" 2>/dev/null || true
	@ rm -f "$(TARGET)" 2>/dev/null
endif
	@echo "Done."

clean-output:
	@echo Removing output file for $(PLATFORM)...
	@$(RMEXE_CMD)
	@echo Done.

purge:
	@echo "NUKING all build artifacts (all OS outputs)..."
ifeq ($(PLATFORM),Windows)
	@if exist "$(OBJ_BASE_DIR)" rmdir /s /q "$(OBJ_BASE_DIR)"
	@if exist "$(TARGET_BASE).exe" del /q "$(TARGET_BASE).exe"
	@if exist "$(TARGET_BASE)" del /q "$(TARGET_BASE)"
else
	@rm -rf "$(OBJ_BASE_DIR)"
	@rm -f "$(TARGET_BASE)"
	@rm -f "$(TARGET_BASE).exe"
endif
	@echo All build outputs removed.

help:
	@$(BLANK_CMD)
	@printf "Available targets:\n"
	@printf "make\tmake release\tBuild in release mode (-O2 -DNDEBUG)\n"
	@printf "make debug\t\tBuild in debug mode (-Og -g -D_DEBUG)\n"
	@printf "make run\t\tBuild and run (release mode)\n"
	@printf "make debug-run\t\tBuild and run (debug mode)\n"
	@printf "make clean\t\tRemove current OS/mode objects + exe\n"
	@printf "make clean-output\tRemove only OS executable\n"
	@printf "make purge\t\tRemove all objects and executables\n"
	@printf "make info\t\tShow build configuration\n"
	@printf "\n"
	@printf "Configurable flags (true/false):\n"
	@printf "WALL=%s\tWERROR=%s\tWEXTRA=%s\tWPEDANTIC=%s\tWSHADOW=%s\n" \
		"$(WALL)" "$(WERROR)" "$(WEXTRA)" "$(WPEDANTIC)" "$(WSHADOW)"
	@printf "\n"
	@printf "Example:\tmake WERROR=false WEXTRA=true\n"
	@$(BLANK_CMD)
