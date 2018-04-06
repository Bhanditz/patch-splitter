{-# Language TemplateHaskell, QuasiQuotes, FlexibleContexts, DeriveDataTypeable, Haskell2010, OverloadedStrings, LambdaCase #-}

module KotlinTemplates
     where

import Data.Text (Text, pack)
import Data.Text as DT (concat, lines)
import Data.Maybe (fromMaybe)
import Data.Data
import Data.Typeable
import Parser
import Data.List
import Text.Shakespeare.Text
import Control.Monad.Supply
import KIdentifiers


{-
 - This file is full of templates of Kotlin code.
 - The templates are written in 'shakespeare' format; details can be found
 - here: https://www.yesodweb.com/book/shakespearean-templates#shakespearean-templates_other_shakespeare
 -
 - Some understanding of the Diff datatype defined in src/Parser.hs is needed to write useful tests.
 -}

kotlinPre :: Text -> Text
kotlinPre class_name = [st|package org.fejoa.fs

import junit.framework.TestCase
import kotlinx.coroutines.experimental.newSingleThreadContext
import kotlinx.coroutines.experimental.runBlocking
import org.fejoa.AccountIO
import org.fejoa.FejoaContext
import org.fejoa.UserData
import org.fejoa.crypto.CryptoSettings
import org.fejoa.crypto.generateSecretKeyData
import org.fejoa.fs.fusejnr.FejoaFuse
import org.fejoa.fs.fusejnr.Utils
import org.fejoa.storage.StorageDir
import org.fejoa.support.StorageLib
import org.fejoa.support.StreamHelper
import org.fejoa.support.toInStream
import org.junit.After
import org.junit.Before
import org.junit.Test

import java.io.*
import java.util.ArrayList


class #{class_name} {
    private val cleanUpDirs: MutableList<String> = ArrayList()
    private val baseDir = "fejoafs"
    private var userData: UserData? = null

    @Before
    fun setUp() = runBlocking {
        cleanUpDirs.add(baseDir)

        val context = FejoaContext(AccountIO.Type.CLIENT, baseDir, "userData",
                newSingleThreadContext("fuse test context"))
        userData = UserData.create(context)
    }

    @After
    fun tearDown() {
        for (dir in cleanUpDirs)
            StorageLib.recursiveDeleteFile(File(dir))
    }

    private suspend fun createStorageDir(userData: UserData, storageContext: String): StorageDir {
        val keyData = CryptoSettings.default.symmetric.generateSecretKeyData()
        val branch = userData.createStorageDir(storageContext, UserData.generateBranchName().toHex(),
                "fuse test branch", keyData)
        val storageDir = userData.getStorageDir(branch)
        userData.commit()
        return storageDir
    }

    @Throws(IOException::class)
    private fun assertContent(file: File, content: String) {
        val read = String(StreamHelper.readAll(FileInputStream(file).toInStream()))
        TestCase.assertEquals(content, read)
    }

    @Test
    fun testBasics() = runBlocking {
        val storageDir = createStorageDir(userData!!, "testContext")
|]

kotlinPost = [st|    }
}
|]

{-kotlinSection-}

{-
 -    val #{initial_file_contents} = storageDir.readString().split("\n")
 -}

{-kotlinApplyChanges :: Change -> ... -> Text-}
kotlinApplyChanges (Change (ChunkHeader oldfile newfile) changeops) = if oldfile == Nothing
    then
        {- We have a diff that should just be solid addition, from nothing, with only one changeop. Create a new file and populate it. -}
        let newtext =
                case changeops of
                    (ChangeOp _ (Lines lines nl)):[] -> DT.concat (map (\case
                            AddLine line -> line
                            _            -> undefined) lines) in
        [st|
        storageDir.writeString(#{newfile}, #{newtext})
        ... commit changes
        |]
    else
        [st|
        val #{initial_file_contents} = storageDir.readString(#{initial_filename}).split("\n")
        #{DT.concat $ map changeops kotlinChangeOpApplication }
        ... commit changes
        |]

kotlinChangeOpApplication :: ChangeOp -> KVariable -> KVariable -> KVariable -> Text
kotlinChangeOpApplication (ChangeOp (Pos startline startextent endline endextent) (Lines changes nl)) (KVariable initial_file_contents) (KVariable diffed_file_contents_accumulator) (KVariable hash) = [st|
    var #{diffed_file_contents_accumulator} = $if startline == 0
      List<String>()
    $else
      #{initial_file_contents}.split(IntRange(0, #{startline - 1})
    $forall change <- changes
      $case change
        $of AddLine line
          #{diffed_file_contents_accumulator}.push(#{line})
        $of RemovedLine line
          // Removed line
        $of UnchangedLine line
          #{diffed_file_contents_accumulator}.push(#{line})
    #{diffed_file_contents_accumulator}.push(#{initial_file_contents}.split(IntRange(#{startextent},  #{initial_file_contents}.length))

|]
