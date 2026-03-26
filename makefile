# ========================
# Project configuration
# ========================
TARGET_BASE := main
CC  := gcc
CXX := g++
SRC_DIR := src
OBJ_BASE_DIR := obj

# Add your custom libraries here (e.g., -lglfw3 -lbox2d)
CUSTOM_LIBS  :=
# Add your custom compiler flags here (e.g., -Wno-missing-field-initializers)
CUSTOM_FLAGS :=

# ========================
# Language standard selection
# ========================
C_STD   ?= c11   # C standard (c89, c99, c11, c17, c2x)
CXX_STD ?= c++17 # C++ standard (c++98, c++11, c++14, c++17, c++20, c++23)

# ========================
# Configurable compiler flags (true/false)
# ========================
WALL      := $(or $(WALL),		true)
WERROR    := $(or $(WERROR),	true)
WEXTRA    := $(or $(WEXTRA),	true)
WPEDANTIC := $(or $(WPEDANTIC),	false)
WSHADOW   := $(or $(WSHADOW),	false)

WARNING_FLAGS := $(if $(filter true,$(WALL)),-Wall) \
                 $(if $(filter true,$(WERROR)),-Werror) \
                 $(if $(filter true,$(WEXTRA)),-Wextra) \
                 $(if $(filter true,$(WPEDANTIC)),-Wpedantic) \
                 $(if $(filter true,$(WSHADOW)),-Wshadow)

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
# OS-specific shell commands
# ========================
ifeq ($(PLATFORM),Windows)
    TARGET := $(TARGET_BASE).exe
    MKDIR_CMD  = if not exist "$(OBJ_DIR)" mkdir "$(OBJ_DIR)"
    RMEXE_CMD  = if exist "$(TARGET)" del /q "$(TARGET)"
    RUN_CMD    = "$(CURDIR)/$(TARGET)"
    BLANK_CMD  = echo.
    PLATFORM_LIBS :=
else
    TARGET := $(TARGET_BASE)
    MKDIR_CMD  = mkdir -p "$(OBJ_DIR)"
    RMEXE_CMD  = rm -f "$(TARGET)"
    RUN_CMD    = "$(CURDIR)/$(TARGET)"
    BLANK_CMD  = echo
    PLATFORM_LIBS :=
endif

# ========================
# Include + lib paths
# ========================
INCLUDES := -I"$(CURDIR)/include"
COMMON_LDFLAGS := -L"$(CURDIR)/lib/$(PLATFORM)" -L"$(CURDIR)/lib" $(CUSTOM_LIBS)
LDFLAGS := $(COMMON_LDFLAGS) $(PLATFORM_LIBS)

# ========================
# Build mode selection
# ========================
ifeq ($(MODE),debug)
    CFLAGS   := $(STD_FLAGS) $(WARNING_FLAGS) $(CUSTOM_FLAGS) -Og -g -D_DEBUG
    CXXFLAGS := $(CXX_STD_FLAGS) $(WARNING_FLAGS) $(CUSTOM_FLAGS) -Og -g -D_DEBUG
endif
ifeq ($(MODE),release)
    CFLAGS   := $(STD_FLAGS) $(WARNING_FLAGS) $(CUSTOM_FLAGS) -O2 -DNDEBUG
    CXXFLAGS := $(CXX_STD_FLAGS) $(WARNING_FLAGS) $(CUSTOM_FLAGS) -O2 -DNDEBUG
endif

# ========================
# Source discovery
# ========================
C_SOURCES   := $(wildcard $(SRC_DIR)/*.c)
CPP_SOURCES := $(wildcard $(SRC_DIR)/*.cpp)
C_OBJECTS   := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(C_SOURCES))
CPP_OBJECTS := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(CPP_SOURCES))
OBJECTS := $(C_OBJECTS) $(CPP_OBJECTS)

ifeq ($(strip $(CPP_SOURCES)),)
    LINKER := $(CC)
else
    LINKER := $(CXX)
endif

.PHONY: all build debug release run clean clean-output help info debug-run purge

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
	@echo Available targets:
	@echo   make / make release  - Build in release mode (-O2 -DNDEBUG)
	@echo   make debug           - Build in debug mode (-Og -g -D_DEBUG)
	@echo   make run             - Build and run (release mode)
	@echo   make debug-run       - Build and run (debug mode)
	@echo   make clean           - Remove current OS/mode objects + exe
	@echo   make clean-output    - Remove only OS executable
	@echo   make purge           - Remove all objects and all executables
	@echo   make info            - Show build configuration
	@$(BLANK_CMD)
	@echo Configurable flags (set to true/false):
	@echo   WALL=$(WALL)
	@echo   WERROR=$(WERROR)
	@echo   WEXTRA=$(WEXTRA)
	@echo   WPEDANTIC=$(WPEDANTIC)
	@echo   WSHADOW=$(WSHADOW)
	@$(BLANK_CMD)
	@echo Example: make WERROR=false WEXTRA=true
	@$(BLANK_CMD)