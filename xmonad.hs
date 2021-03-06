

{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  XMonad.Config.Arossato
-- Copyright   :  (c) Andrea Rossato 2007
-- License     :  BSD3-style (see LICENSE)
--
-- Maintainer  :  andrea.rossato@unibz.it
-- Stability   :  stable
-- Portability :  portable
--
-- This module specifies my xmonad defaults.
--
------------------------------------------------------------------------


module Main (main) where 
import qualified Data.Map as M

import XMonad hiding ( (|||) )
import qualified XMonad.StackSet as W
import XMonad.Hooks.SetWMName
import XMonad.Actions.CycleWS
import XMonad.Hooks.DynamicLog hiding (xmobar)
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ServerMode
import XMonad.Layout.Accordion
import XMonad.Layout.LayoutCombinators
import XMonad.Layout.Magnifier
import XMonad.Layout.NoBorders
import XMonad.Layout.SimpleFloat
import XMonad.Layout.Tabbed
import XMonad.Layout.WindowArranger
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Prompt.Ssh
import XMonad.Prompt.Theme
import XMonad.Prompt.Window
import XMonad.Prompt.XMonad
import XMonad.Util.Run
import XMonad.Util.Themes

-- $usage
-- The simplest way to use this configuration module is to use an
-- @~\/.xmonad\/xmonad.hs@ like this:
--
-- > module Main (main) where
-- >
-- > import XMonad
-- > import XMonad.Config.Arossato (arossatoConfig)
-- >
-- > main :: IO ()
-- > main = xmonad =<< arossatoConfig
--
-- NOTE: that I'm using xmobar and, if you don't have xmobar in your
-- PATH, this configuration will produce an error and xmonad will not
-- start. If you don't want to install xmobar get rid of this line at
-- the beginning of 'arossatoConfig'.
--
-- You can use this module also as a starting point for writing your
-- own configuration module from scratch. Save it as your
-- @~\/.xmonad\/xmonad.hs@ and:
--
-- 1. Change the module name from
--
-- > module XMonad.Config.Arossato
-- >     ( -- * Usage
-- >       -- $usage
-- >       arossatoConfig
-- >     ) where
--
-- to
--
-- > module Main where
--
-- 2. Add a line like:
--
-- > main = xmonad =<< arossatoConfig
--
-- 3. Start playing with the configuration options...;)
main :: IO ()
main = xmonad =<< arossatoConfig

arossatoConfig = do
    return $ defaultConfig
         { workspaces         = ["home","var","dev","mail","web","doc"] ++
                                map show [7 .. 9 :: Int]
         , manageHook         = newManageHook
	 , layoutHook	      = avoidStruts $ decorated ||| noBorders mytabs ||| otherLays
         , terminal           = "urxvt +sb"
         , normalBorderColor  = "white"
         , focusedBorderColor = "black"
         , keys               = newKeys
         , handleEventHook    = serverModeEventHook
         , focusFollowsMouse  = False
	 , startupHook = setWMName "LG3D"

         }
    where
      -- layouts
      mytabs    =       tabbed shrinkText (theme smallClean)
      decorated = simpleFloat' shrinkText (theme smallClean)
      tiled     = Tall 1 (3/100) (1/2)
      otherLays = windowArrange   $
		  tiled |||
                  noBorders Full

      -- manageHook
      myManageHook  = composeAll [ resource =? "win"          --> doF (W.shift "doc") -- xpdf
                                 , resource =? "firefox-bin"  --> doF (W.shift "web")
                                 ]
      newManageHook = myManageHook

      -- xmobar
      myDynLog    h = dynamicLogWithPP defaultPP
                      { ppCurrent = xmobarColor "yellow" "" . wrap "[" "]"
                      , ppTitle   = xmobarColor "green"  "" . shorten 40
                      , ppVisible = wrap "(" ")"
                      , ppOutput  = hPutStrLn h
                      }

      -- key bindings stuff
      defKeys    = keys defaultConfig
      delKeys x  = foldr M.delete           (defKeys x) (toRemove x)
      newKeys x  = foldr (uncurry M.insert) (delKeys x) (toAdd    x)
      -- remove some of the default key bindings
      toRemove x =
          [ (modMask x              , xK_q) ] ++
          -- I want modMask .|. shiftMask 1-9 to be free!
          [(shiftMask .|. modMask x, k) | k <- [xK_1 .. xK_9]]
      -- These are my personal key bindings
      toAdd x   =
          [ ((modMask x              , xK_F12   ), xmonadPrompt      defaultXPConfig     )
          , ((modMask x              , xK_p     ), shellPrompt       defaultXPConfig     )
          , ((modMask x              , xK_F4    ), sshPrompt         defaultXPConfig     )
          , ((modMask x              , xK_F5    ), themePrompt       defaultXPConfig     )
          , ((modMask x              , xK_F6    ), windowPromptGoto  defaultXPConfig     )
          , ((modMask x              , xK_F7    ), windowPromptBring defaultXPConfig     )
          , ((modMask x              , xK_comma ), prevWS                                )
          , ((modMask x              , xK_period), nextWS                                )
          , ((modMask x              , xK_Right ), windows W.focusDown                   )
          , ((modMask x              , xK_Left  ), windows W.focusUp                     )
          -- other stuff: launch some useful utilities
          , ((modMask x              , xK_F2    ), spawn "urxvt -fg white -bg black +sb" )
          , ((modMask x .|. shiftMask, xK_F4    ), spawn "~/bin/dict.sh"                 )
          , ((modMask x .|. shiftMask, xK_F5    ), spawn "~/bin/urlOpen.sh"              )
          , ((modMask x .|. shiftMask, xK_t     ), spawn "~/bin/teaTime.sh"              )
          , ((modMask x              , xK_c     ), kill                                  )
          , ((modMask x .|. shiftMask, xK_comma ), sendMessage (IncMasterN   1 )         )
          , ((modMask x .|. shiftMask, xK_period), sendMessage (IncMasterN (-1))         )
          -- commands fo the Magnifier layout
          , ((modMask x .|. controlMask              , xK_plus ), sendMessage MagnifyMore)
          , ((modMask x .|. controlMask              , xK_minus), sendMessage MagnifyLess)
          , ((modMask x .|. controlMask              , xK_o    ), sendMessage ToggleOff  )
          , ((modMask x .|. controlMask .|. shiftMask, xK_o    ), sendMessage ToggleOn   )
          -- windowArranger
          , ((modMask x .|. controlMask              , xK_a    ), sendMessage  Arrange           )
          , ((modMask x .|. controlMask .|. shiftMask, xK_a    ), sendMessage  DeArrange         )
          , ((modMask x .|. controlMask              , xK_Left ), sendMessage (DecreaseLeft   10))
          , ((modMask x .|. controlMask              , xK_Up   ), sendMessage (DecreaseUp     10))
          , ((modMask x .|. controlMask              , xK_Right), sendMessage (IncreaseRight  10))
          , ((modMask x .|. controlMask              , xK_Down ), sendMessage (IncreaseDown   10))
          , ((modMask x .|. shiftMask                , xK_Left ), sendMessage (MoveLeft       10))
          , ((modMask x .|. shiftMask                , xK_Right), sendMessage (MoveRight      10))
          , ((modMask x .|. shiftMask                , xK_Down ), sendMessage (MoveDown       10))
          , ((modMask x .|. shiftMask                , xK_Up   ), sendMessage (MoveUp         10))
          -- gaps
          , ((modMask x                              , xK_b    ), sendMessage  ToggleStruts      )

          ] ++
          -- Use modMask .|. shiftMask .|. controlMask 1-9 instead
          [( (m .|. modMask x, k), windows $ f i)
           | (i, k) <- zip (workspaces x) [xK_1 .. xK_9]
          ,  (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask .|. controlMask)]
          ]


