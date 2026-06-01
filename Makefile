# Makefile для denote-solo
#
# Использование:
#   make            — то же, что make compile
#   make compile    — байт-компиляция в чистом Emacs (-Q), затем чистка .elc
#   make lint       — checkdoc + базовые предупреждения компилятора
#   make clean      — удалить артефакты сборки (*.elc)
#
# Переменные можно переопределять из командной строки, например:
#   make compile DENOTE=/другой/путь/к/denote

EMACS ?= emacs
DENOTE ?= $(HOME)/.emacs.d/elpaca/builds/denote
PACKAGE = denote-solo.el

# -Q     — чистый Emacs: не читает init.el, не знает про elpaca-пакеты
# --batch — без интерфейса, всё в stdout/stderr
# -L DIR  — добавить DIR в load-path, чтобы (require 'denote) нашёлся
BATCH = $(EMACS) -Q --batch -L $(DENOTE)

.PHONY: all compile lint clean

all: compile

compile:
	$(BATCH) -f batch-byte-compile $(PACKAGE)
	$(MAKE) clean

lint:
	$(BATCH) -f batch-byte-compile $(PACKAGE)
	$(BATCH) --eval '(checkdoc-file "$(PACKAGE)")'
	$(MAKE) clean

clean:
	rm -f *.elc
