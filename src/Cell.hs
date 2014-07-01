-----------------------------------------------------------------------------
--
-- Module      :  Cell
-- Copyright   :
-- License     :  BSD3
--
-- Maintainer  :  agocorona@gmail.com
-- Stability   :  experimental
-- Portability :
--
-- |
--
-----------------------------------------------------------------------------

module Cell (boxCell, cell)  where
import View
import Data.Typeable
import Control.Monad.IO.Class
import qualified Data.Map as V
import Data.Default
import Haste
import Control.Monad.State
import Control.Applicative
import Data.Monoid
import Unsafe.Coerce
import Control.Concurrent.MVar

boxCell :: (Show a,Read a, Typeable a) => String -> Widget a -> Widget a
boxCell id formula = res where
  res= mkcell id
   (\mv -> do
       x <- getParam (Just id) "text" mv `raiseEvent` OnKeyUp
       setCell id x
       return x )
   (runWidgetId (do
       x <- formula
       setCell id x
       liftIO $ update id (x `asTypeOf` getType res )) id)

  getType :: Widget a -> a
  getType= undefined

  update id x = withElem id $ \e -> do
     liftIO $ print $ "set " ++ id ++"="++ show x
     setAttr  e "value" (show1 x)

  show1 x= if typeOf x== typeOf (undefined :: String) then unsafeCoerce x else show x

mkcell :: Typeable a => String -> (Maybe a -> Widget a) -> IO (Maybe  ()) -> Widget a
mkcell name widget update =  View $ do
    stored <- cell1 name `onNothing` return def
    wupdated update
    rw@(FormElm render r') <- runView $ widget stored
    r <- case r' of
       Nothing ->  return stored
       justx@(Just x) -> addNumber name x >> return justx
    return $ FormElm render r
  where
  addNumber i x= do
    xs <- getSessionData `onNothing` return  V.empty
    setSData $ V.insert i x xs -- :: V.Map String String)


setCell i v= do
  xs <- getSData <|> return V.empty
  setSData $ V.insert i v xs  -- :: V.Map String String)

--cell :: Typeable a => String -> StateT MFlowState IO  a
cell i =  do
  xs <-  getSData  -- :: Widget (V.Map String String)
  case  V.lookup i xs of
         Nothing -> do
           empty
         Just x  ->   return x

cell1 :: Typeable a => String -> StateT MFlowState IO  (Maybe a)
cell1 name= do
  mxs <- getSessionData
  case mxs of
    Nothing -> return Nothing
    Just xs -> return $ V.lookup name xs


onNothing mx mn= do
   m <- mx
   case m of
     Nothing -> mn
     Just x  -> return x


--wupdated ::  Widget () -> StateT MFlowState IO ()
wupdated  update=  liftIO $  do
   bc <- takeMVar callbacks
   putMVar callbacks $  update >> bc

