import Data.Text (Text, pack, unlines)
data Patch = Patch CommitLine CommitMetadata Diff
data ChangeOp = ChangeOp Pos Lines
data Pos = Pos Int Int Int Int

data Lines = Lines [Line] Bool
data CommitMetadata = CommitMetadata Text Text Text Text Text {- Commit comment, author, author date, commit, commit date -}

data ChunkHeader = ChunkHeader (Maybe Text) Text
liness :: Lines
  = (addline / removeline / unchangedline)+ ("\ No newline at end of file" nl)? { Lines (catMaybes $1) ($2 == Nothing) }
indentedtext :: Text
  = ("    " aftertext nl { $1 })+ { Data.Text.unlines $1 }

  = "Author:     " aftertext nl "AuthorDate: " aftertext nl "Commit:     " aftertext nl "CommitDate: " aftertext nl indentedtext { CommitMetadata $9 $1 $3 $5 $7 }

chunkheader :: ChunkHeader
  = "diff --git a/" [^ \n\r]+ " b/" [^ \n\r]+ nl ("new file mode " [^ \n\r]+ nl { "New File" })? "index " [^ \n\r]+ " " [^ \n\r]+ nl "--- a/" [^ \n\r]+ nl "+++ b/" [^ \n\r]+ nl { 
        case $4 of
          Nothing -> (ChunkHeader Nothing (pack $2))
          _       -> (ChunkHeader (Just $ pack $1) (pack $2))
    }

pos :: Pos
  = "@@ -" [0-9]+ "," [0-9]+ " +" [0-9]+ "," [0-9]+ " @@" nl { Pos (read $1) (read $2) (read $3) (read $4) }

changeop :: ChangeOp
  = pos nl liness { ChangeOp $1 $3 }