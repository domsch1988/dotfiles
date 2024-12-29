(defvar elpaca-installer-version 0.8)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode)
  (setq use-package-always-ensure t))

(use-package transient
  :defer t
  )

(use-package forge)

(use-package emacs
  :ensure nil
  :config
  (defun domacs/indent-buffer ()
    "Function to indent the entire buffer automatically"
    (interactive)
    (save-excursion
      (indent-region (point-min) (point-max) nil))
    (save-buffer))
  :init
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  :custom-face
  (default ((t (:family "Iosevka Comfy" :height 110))))
  :bind
  ("M-h" . windmove-left)
  ("M-j" . windmove-down)
  ("M-k" . windmove-up)
  ("M-l" . windmove-right)
  ("C-c b e" . eval-buffer)
  ("C-c b i" . domacs/indent-buffer)
  ("C-c q r" . restart-emacs)
  ("<escape>" . keyboard-escape-quit))

(use-package modus-themes
  :custom
  (modus-themes-custom-auto-reload t)
  (modus-themes-italic-constructs t)
  (modus-themes-bold-constructs t)
  (modus-themes-disable-other-themes t)
  (modus-themes-prompts '(italic bold))
  ;;(modus-themes-variable-pitch-ui t)
  ( modus-themes-completions
    '((matches . (extrabold))
      (selection . (semibold italic text-also))))
  (modus-themes-headings
   '((1 . (rainbow bold 1.5))
     (2 . (rainbow bold 1.0))
     (3 . (rainbow semibold 1.0))
     (t . (rainbow semibold 1.0))))
  (modus-themes-common-palette-overrides
   '(
     (fringe unspecified)
     ))
  (modus-themes-to-toggle '(modus-operandi-tinted modus-vivendi-tinted))
  :init
  (load-theme 'modus-vivendi-tinted t)
  :bind
  ("C-c u t" . modus-themes-toggle))

(use-package nerd-icons)

(use-package which-key
  :defer t
  :custom
  (which-key-prefix-prefix " ")
  (which-key-separator "  ")
  (which-key-max-display-columns 1)
  (which-key-add-column-padding 5)
  (which-key-frame-max-width 200)
  (which-key-max-description-length 60)
  (which-key-side-window-max-width 0.6)
  :config
  (which-key-mode 1)
  (which-key-add-key-based-replacements "C-c b" "Buffer")
  (which-key-add-key-based-replacements "C-c n" "Notes")
  (which-key-add-key-based-replacements "C-c q" "Power")
  (which-key-add-key-based-replacements "C-c u" "UI")
  )

;; Floating which-key
(use-package which-key-posframe
  :custom
  (which-key-posframe-poshandler 'posframe-poshandler-window-bottom-right-corner)
  :config
  (which-key-posframe-mode))

(use-package vertico
  :defer t
  :custom
  (vertico-scroll-margin 0) ;; Different scroll margin
  (vertico-count 15) ;; Show more candidates
  (vertico-resize t) ;; Grow and shrink the Vertico minibuffer
  (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  :init
  (vertico-mode))

(use-package vertico-posframe
  :config
  (vertico-posframe-mode 1))

(use-package orderless
  :defer t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :defer t
  :bind (:map minibuffer-local-map
	      ("M-A" . marginalia-cycle))
  :init
  (marginalia-mode))

(use-package consult
  :defer t
  :bind
  ("C-c ," . consult-line)
  )

(use-package embark
  :defer t
  :ensure t
  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("M-." . embark-dwim)        ;; good alternative: M-.
   )
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  :config
  (add-to-list 'display-buffer-alist
	       '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :defer t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package embark-vc
  :defer t
  :after embark)

;;; Completion
(use-package corfu
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-quit-no-match 'separator)
  :init
  (global-corfu-mode)
  :bind
  (:map corfu-map
  	("RET" . nil)
  	)
  )

(use-package cape
  :defer t
  :bind ("C-c p" . cape-prefix-map)
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  )

(use-package yasnippet-capf
  :after cape
  :config
  (add-to-list 'completion-at-point-functions #'yasnippet-capf))

(use-package magit
  :defer t
  :custom
  (magit-log-margin '(t age magit-log-margin-width t 20))
  :bind
  ("C-c g g" . magit-status)
  )

(use-package git-gutter-fringe
  :config
  (fringe-helper-define 'git-gutter-fr:added nil
    "........"
    "........"
    "........"
    "........"
    "........"
    "........"
    "........"
    "........")
  (set-face-foreground 'git-gutter-fr:added    "green")

  (fringe-helper-define 'git-gutter-fr:modified nil
    "........"
    "........"
    "........"
    "........"
    "........"
    "........"
    "........"
    "........")
  (set-face-foreground 'git-gutter-fr:modified   "yellow")

  (fringe-helper-define 'git-gutter-fr:deleted nil
    "........"
    "........"
    "........"
    "........"
    "........"
    "........"
    "........"
    "........")
  (set-face-foreground 'git-gutter-fr:deleted    "red")
  (global-git-gutter-mode 1)
  )


(use-package blamer
  :defer t
  :bind
  ("C-c g b" . blamer-mode)
  )

;;; Org
(use-package org
  :ensure nil
  :defer t
  :config
  (setq org-capture-templates
	'(("t" "Todo" entry (file+headline "~/Dokumente/Org/Work/tasks.org" "Tasks")
	   "* TODO %?\n  %i")
	  ("n" "Quicknote" entry (file+headline "~/Dokumente/Org/Work/notes.org" "Notes")
	   "* %?\n  %i\n  %a"))
	)
  :bind
  ("C-c n t" . org-capture)
  :custom
  (org-startup-folded 'showeverything)
  (calendar-date-style 'european)
  (calendar-week-start-day 1)
  (calendar-month-width 29)
  (calendar-month-digit-width 19)
  (org-agenda-files "~/Dokumente/agendafiles")
  (org-tag-alist
   '(
     ;; Places
     ("project" . ?p)
     ("emacs" . ?e)

     ;; Activities
     ("planning" . ?n)
     ("ansible" . ?a)
     ("update" . ?u)
     ("documentation" . ?d)
     ("email" . ?m)
     ("calls" . ?c)
     ("errands" . ?r)))
  (org-agenda-time-grid
   '((daily today remove-match) (700 800 900 1000 1100 1200 1300 1400 1500 1600 1700)
     " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"))
  )

(use-package org-modern
  :defer t
  :custom
  (org-modern-star 'replace)
  (org-modern-todo t)
  (org-modern-replace-stars " 󰲠󰲢󰲤󰲦")
  (org-modern-hide-stars " ")
  (org-modern-fold-stars '(
			   ("▶" . "▼")
			   ("▷" . "▽")
			   ("⯈" . "⯆")
			   ("▹" . "▿")
			   ("▸" . "▾")))
  (org-modern-list '((?+ . "")
		     (?- . "󰧞")
		     (?* . "󰓎")))
  :hook
  (org-mode . org-modern-mode)
  (org-agenda-finalize . org-modern-agenda))

(use-package org-roam
  :defer t
  :custom
  (org-roam-db-autosync-mode t)
  (org-roam-directory "~/Dokumente/Org/Work/01_Roam"))

(use-package org-ql)

(use-package org-journal
  :defer t
  :custom
  (org-journal-file-type 'weekly)
  (org-journal-dir "~/Dokumente/Org/Work/Journal")
  (org-journal-time-format "")
  (org-journal-file-format "%Y%m%d.org")
  )

(use-package consult-org-roam
  :defer t
  :after org-roam
  :init
  ;; Activate the minor mode
  (consult-org-roam-mode 1)
  :custom
  ;; Use `ripgrep' for searching with `consult-org-roam-search'
  (consult-org-roam-grep-func #'consult-ripgrep)
  ;; Configure a custom narrow key for `consult-buffer'
  (consult-org-roam-buffer-narrow-key ?r)
  ;; Display org-roam buffers right after non-org-roam buffers
  ;; in consult-buffer (and not down at the bottom)
  (consult-org-roam-buffer-after-buffers t)
  :config
  ;; Eventually suppress previewing for certain functions
  (consult-customize
   consult-org-roam-forward-links
   :preview-key "M-."))

;;; Dashboard
(use-package dashboard
  :custom
  (dashboard-center-content t)
  (dashboard-vertically-center-content t)
  (dashboard-startupify-list
   '(
     dashboard-insert-banner
     dashboard-insert-newline
     dashboard-insert-init-info
     dashboard-insert-newline
     dashboard-insert-items
     ))
  (dashboard-set-file-icons t)
  (dashboard-set-heading-icons t)
  (dashboard-startup-banner "~/.config/emacs/images/emacs-logo-1.png")
  (dashboard-items '((recents   . 10)
                     (projects  . 5)
                     (agenda    . 5)))
  :custom-face
  (dashboard-heading ((t (:family "Noto Sans" :weight bold :height 150 :foreground "#7E5CB6"))))
  :config
  (add-hook 'elpaca-after-init-hook #'dashboard-insert-startupify-lists)
  (add-hook 'elpaca-after-init-hook #'dashboard-initialize)
  (dashboard-setup-startup-hook))

(use-package expand-region
  :bind
  ("C-ö" . er/expand-region))

(use-package notmuch)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(window-divider ((t (:foreground "cyan")))))
