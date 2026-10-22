# Tmux Keybindings

## Navigation (no prefix)
Ctrl+h/j/k/l    Pane navigation (vim-aware)  #pane #navigate #move #vim #select
Ctrl+\    Last pane (vim-aware)  #pane #last #switch #back #vim
M-h    Previous window  #window #navigate #prev #left
M-l    Next window  #window #navigate #next #right
M-j    Next session  #session #navigate #next #down #switch
M-k    Previous session  #session #navigate #prev #up #switch
M-s    Sesh session picker (also in zsh outside tmux)  #session #switch #open #picker #sesh #alias
Ctrl+Alt+Arrows    Resize pane  #pane #resize #grow #shrink

## Quick Actions (C-a + key)
C-a + |    Split pane side by side  #pane #split #horizontal #vertical #create
C-a + -    Split pane stacked  #pane #split #vertical #horizontal #create
C-a + x    Kill pane  #pane #close #kill #delete
C-a + o    Sesh session picker  #session #switch #open #picker #sesh
C-a + f    Toggle floating pane (floax)  #float #floax #popup #toggle
C-a + v    Enter copy mode (vi)  #copy #mode #scroll #search #select
C-a + d    Detach from session  #session #detach #exit #leave
C-a + r    Reload tmux config  #reload #config #refresh #source
C-a + t    Quick-add task (tsk)  #todo #task #add #tsk
C-a + T    Pick task (tsk)  #todo #task #pick #tsk
C-a + S    Stash popup (fzf project picker)  #stash #quickflow #popup #fzf
C-a + N    Quickflow inbox next  #quickflow #inbox #next #notification
C-a + Tab    Window switcher (all sessions)  #window #switch #picker #search #jump
C-a + S-Tab    Session switcher  #session #switch #picker #search #jump
C-a + C-g    File picker: insert repo path  #file #path #picker #fzf #insert #claude
C-a + W    Workmux dashboard  #workmux #agent #worktree #dashboard #claude
C-a + L    Workmux: jump to last finished agent  #workmux #agent #done #jump #claude
C-a + g    Move/resize floating pane table  #pane #float #move #resize
C-a + b    Send prefix to nested session  #nested #prefix #inner #remote
C-a + C-a    Send prefix to nested session  #nested #prefix #inner #remote
C-a + 0-9    Select window by number  #window #switch #jump #number

## Window Table (C-a w → key)
C-a w n    New window (current dir)  #window #new #create #open
C-a w x    Kill window (confirm)  #window #close #kill #delete
C-a w r    Rename window  #window #rename
C-a w h    Swap window left  #window #swap #move #left #reorder
C-a w l    Swap window right  #window #swap #move #right #reorder
C-a w f    Find window  #window #search #find
C-a w a    Last window (alternate)  #window #switch #last #back #alternate
C-a w s    Window tree picker  #window #pick #tree #select #choose
C-a w g    Lazygit window (reuse if open)  #window #git #lazygit #open

## Pane Table (C-a p → key)
C-a p |    Split pane side by side  #pane #split #horizontal #create
C-a p -    Split pane stacked  #pane #split #vertical #create
C-a p x    Kill pane  #pane #close #kill #delete
C-a p z    Toggle pane zoom (fullscreen)  #pane #zoom #fullscreen #toggle #maximize
C-a p h/j/k/l    Select pane by direction  #pane #navigate #move #select
C-a p H/J/K/L    Resize pane (repeatable)  #pane #resize #grow #shrink
C-a p a    Last pane (alternate)  #pane #switch #last #back #alternate
C-a p m    Mark pane  #pane #mark #tag
C-a p {    Swap pane up  #pane #swap #move #reorder #up
C-a p }    Swap pane down  #pane #swap #move #reorder #down
C-a p !    Break pane into window  #pane #window #break #promote
C-a p Space    Cycle layout  #pane #layout #cycle #next
C-a p o    Rotate panes  #pane #rotate #reorder #cycle
C-a p q    Display pane numbers  #pane #number #identify #pick

## Session Table (C-a s → key)
C-a s o    Sesh session picker  #session #switch #open #picker #sesh
C-a s n    New session  #session #new #create
C-a s r    Rename session  #session #rename
C-a s a    Last session via sesh (alternate)  #session #switch #last #back #alternate #sesh
C-a s x    Kill session (confirm)  #session #close #kill #delete
C-a s d    Detach from session  #session #detach #exit #leave
C-a s s    Session tree picker  #session #pick #tree #select #choose
C-a s R    Switch to repo root session via sesh  #session #switch #root #worktree #sesh

## Copy Mode (C-a v to enter)
v    Begin selection  #copy #select #highlight
C-v    Toggle rectangle selection  #copy #select #rectangle #block
y    Yank to clipboard  #copy #yank #clipboard #paste
Escape    Cancel copy mode  #copy #cancel #exit
H    Start of line  #copy #navigate #home #line
L    End of line  #copy #navigate #end #line

## Plugins
C-a + C-f    Extrakto: extract text from pane  #plugin #extract #text #fzf #copy #grab
C-a + C-l    FZF links finder  #plugin #links #url #open #browser
C-a + F    Filter pane output  #plugin #filter #search #grep #text
C-a + P    Floax menu  #plugin #float #floax #menu #popup
C-a + BSpace    Command palette (keys)  #plugin #command #palette #menu #search
C-a + M-m    Command palette (commands)  #plugin #command #palette #commands
C-a + I    Install TPM plugins  #plugin #tpm #install
C-a + U    Update TPM plugins  #plugin #tpm #update
C-a + M-u    Clean TPM plugins  #plugin #tpm #clean #remove

## Other
C-a + :    Command prompt  #command #prompt #type #manual
C-a + ?    Show cheatsheet  #help #cheatsheet #keys #bindings
C-a + /    Describe a key binding  #help #keys #describe #bindings
C-a w|p|s ?    Key table palette  #help #keys #palette #window #pane #session
C-a + C    Customize options  #config #customize #settings
C-a + ~    Show messages  #messages #log #history #debug
C-a + i    Display info  #info #display #status
