-- Fix tables that have a single row with multiline cells to have a single line
-- per cell (used for keywords and names, eg. in awk, bc, c17)
function Table(tbl)
  -- Remove paragraphs, they break tables
  tbl = tbl:walk {
    Para = function(el)
      return el.content
    end
  }

  local body = tbl.bodies[1]

  if (
    #tbl.head.rows ~= 0 or
    #body.body ~= 1 or
    body.body[1].cells[1].content[1].content[1].tag ~= "Strong"
  ) then
    -- Remove line breaks, they break tables
    return tbl:walk {
      LineBreak = function()
        return " "
      end
    }
  end

  local columns = body.body[1].cells:map(
    function (column)
      return column.content[1].content[1].content:filter(
        function (inline)
          return inline.tag ~= 'LineBreak'
        end
      )
    end
  )

  local rows = {}
  for i = 1, #columns[1] do
    local cells = columns:map(
      function (inlines)
        return pandoc.Cell(inlines[i] and pandoc.Strong(inlines[i]) or {})
      end
    )
    table.insert(rows, pandoc.Row(cells))
  end

  body.body = rows

  return tbl
end
