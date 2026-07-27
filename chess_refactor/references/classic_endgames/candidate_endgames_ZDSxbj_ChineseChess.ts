import type { ChessColor, ChessPosition } from '@/composables/ChessPiece'

declare const window: any

export type EndgamePieceType = 'King' | 'Advisor' | 'Bishop' | 'Horse' | 'Rook' | 'Cannon' | 'Pawn'
export interface EndgamePiece {
  type: EndgamePieceType
  color: ChessColor
  position: ChessPosition
}

export interface EndgameScenario {
  id: string
  name: string
  difficulty: '初级' | '中级' | '高级'
  goal: string
  description: string
  initialTurn: ChessColor
  initialPieces: EndgamePiece[]
  maxMoves?: number
  aiLevel?: number
  tags?: string[]
}

export interface ValidationResult {
  valid: boolean
  errors: string[]
}

const p = (type: EndgamePieceType, color: ChessColor, x: number, y: number): EndgamePiece => ({ type, color, position: { x, y } })

const scenarios: EndgameScenario[] = [
  {
    id: 'qi-xing-ju-hui',
    name: '七星聚会',
    difficulty: '高级',
    goal: '',
    description: '双车带兵压迫，黑方双车象卒防守，考验快攻收官。',
    initialTurn: 'red',
    aiLevel: 6,
    tags: ['双车', '快攻收官'],
    initialPieces: [
      // 红方
      p('King', 'red', 4, 9),
      p('Pawn', 'red', 3, 1),
      p('Pawn', 'red', 5, 2),
      p('Pawn', 'red', 8, 5),
      p('Cannon', 'red', 7, 7),
      p('Rook', 'red', 6, 9),
      p('Rook', 'red', 7, 9),
      // 黑方
      p('King', 'black', 5, 0),
      p('Rook', 'black', 4, 0),
      p('Bishop', 'black', 4, 2),
      p('Pawn', 'black', 1, 7),
      p('Pawn', 'black', 4, 7),
      p('Pawn', 'black', 5, 8),
      p('Pawn', 'black', 3, 8),
    ],
  },
  {
    id: 'ma-yue-tan-xi',
    name: '马跃檀溪',
    difficulty: '中级',
    goal: '',
    description: '车炮双线压制，兵助攻完成突破收官。',
    initialTurn: 'red',
    aiLevel: 6,
    tags: ['车炮配合', '中局快攻'],
    initialPieces: [
      // 红方
      p('King', 'red', 5, 9), // 帅 6,10
      p('Bishop', 'red', 2, 9), // 相 3,10
      p('Pawn', 'red', 4, 1), // 兵 5,2
      p('Rook', 'red', 8, 4), // 车 9,5
      p('Rook', 'red', 8, 5), // 车 9,6
      p('Cannon', 'red', 7, 6), // 炮 8,7
      p('Cannon', 'red', 8, 6), // 炮 9,7
      // 黑方
      p('King', 'black', 3, 0), // 将 4,1
      p('Horse', 'black', 5, 0), // 马 6,1
      p('Pawn', 'black', 5, 7), // 卒 6,8
      p('Pawn', 'black', 4, 8), // 卒 5,9
      p('Rook', 'black', 3, 6), // 车 4,7
    ],
  },
  {
    id: 'pao-zha-liang-lang',
    name: '炮炸两狼关',
    difficulty: '高级',
    goal: '',
    description: '炮牵双车的突击，识别薄弱点一击制胜。',
    initialTurn: 'red',
    aiLevel: 6,
    tags: ['炮击', '突破'],
    initialPieces: [
      // 红方
      p('King', 'red', 4, 9), // 帅 5,10
      p('Cannon', 'red', 5, 0), // 炮 6,1
      p('Rook', 'red', 6, 0), // 车 7,1
      p('Pawn', 'red', 1, 1), // 兵 2,2
      p('Pawn', 'red', 5, 1), // 兵 6,2
      p('Pawn', 'red', 6, 2), // 兵 7,3
      p('Pawn', 'red', 4, 6), // 兵 5,7
      // 黑方
      p('King', 'black', 3, 0), // 将 4,1
      p('Rook', 'black', 1, 0), // 车 2,1
      p('Rook', 'black', 5, 8), // 车 6,9
      p('Cannon', 'black', 8, 3), // 炮 9,4
      p('Pawn', 'black', 6, 6), // 卒 7,7
      p('Pawn', 'black', 3, 8), // 卒 4,9
    ],
  },
  {
    id: 'xiao-zheng-dong',
    name: '小征东',
    difficulty: '中级',
    goal: '',
    description: '双炮压线与双车前出，配合兵线推进。',
    initialTurn: 'red',
    aiLevel: 6,
    tags: ['双炮', '双车', '推进'],
    initialPieces: [
      // 红方
      p('King', 'red', 3, 9), // 帅 4,10
      p('Pawn', 'red', 3, 1), // 兵 4,2
      p('Pawn', 'red', 4, 1), // 兵 5,2
      p('Pawn', 'red', 6, 6), // 兵 7,7
      p('Cannon', 'red', 8, 3), // 炮 9,4
      p('Cannon', 'red', 8, 4), // 炮 9,5
      p('Rook', 'red', 7, 5), // 车 8,6
      p('Rook', 'red', 8, 6), // 车 9,7
      // 黑方
      p('King', 'black', 5, 0), // 将 6,1
      p('Cannon', 'black', 4, 0), // 炮 5,1
      p('Rook', 'black', 5, 2), // 车 6,3
      p('Bishop', 'black', 0, 2), // 象 1,3
      p('Pawn', 'black', 3, 7), // 卒 4,8
      p('Pawn', 'black', 4, 8), // 卒 5,9
    ],
  },
  {
    id: 'qiu-yin-jiang-long',
    name: '蚯蚓降龙',
    difficulty: '中级',
    goal: '',
    description: '红方车兵协同，黑方卒阵分布，注意突破口。',
    initialTurn: 'red',
    aiLevel: 6,
    tags: ['车兵协同'],
    initialPieces: [
      // 红方（玩家）
      p('King', 'red', 5, 9), // 帅 6,10
      p('Rook', 'red', 5, 5), // 车 6,6
      p('Rook', 'red', 8, 9), // 车 9,10
      p('Pawn', 'red', 8, 5), // 兵 9,6
      // 黑方（AI）
      p('King', 'black', 4, 0), // 将 5,1
      p('Advisor', 'black', 3, 0), // 士 4,1
      p('Advisor', 'black', 4, 1), // 士 5,2
      p('Bishop', 'black', 4, 2), // 象 5,3
      p('Pawn', 'black', 2, 4), // 卒 3,5
      p('Pawn', 'black', 4, 8), // 卒 5,9
      p('Pawn', 'black', 6, 8), // 卒 7,9
    ],
  },
  {
    id: 'da-jiu-lian-huan',
    name: '大九连环',
    difficulty: '高级',
    goal: '',
    description: '兵形牵制与中路突破，注意炮车联动。',
    initialTurn: 'red',
    aiLevel: 6,
    tags: ['兵阵', '炮车配合'],
    initialPieces: [
      // 红方
      p('King', 'red', 4, 9), // 帅 5,10
      p('Pawn', 'red', 0, 1), // 兵 1,2
      p('Pawn', 'red', 4, 1), // 兵 5,2
      p('Pawn', 'red', 8, 1), // 兵 9,2
      p('Pawn', 'red', 4, 5), // 兵 5,6
      p('Pawn', 'red', 6, 5), // 兵 7,6
      p('Cannon', 'red', 7, 7), // 炮 8,8
      p('Cannon', 'red', 7, 8), // 炮 8,9
      p('Rook', 'red', 7, 9),   // 车 8,10
      // 黑方
      p('King', 'black', 5, 0), // 将 6,1
      p('Rook', 'black', 5, 2), // 车 6,3
      p('Pawn', 'black', 2, 8), // 卒 3,9
      p('Pawn', 'black', 3, 8), // 卒 4,9
      p('Pawn', 'black', 8, 3), // 卒 9,4
      p('Cannon', 'black', 8, 2), // 炮 9,3
    ],
  },
  {
    id: 'dai-zi-ru-chao',
    name: '带子入朝',
    difficulty: '中级',
    goal: '',
    description: '车兵快攻直指中路，注意牵制与护帅。',
    initialTurn: 'red',
    aiLevel: 6,
    tags: ['快攻', '车兵'],
    initialPieces: [
      // 红方
      p('King', 'red', 4, 9), // 帅 5,10
      p('Advisor', 'red', 5, 9), // 仕 6,10
      p('Rook', 'red', 7, 1), // 车 8,2
      p('Pawn', 'red', 2, 0), // 兵 3,1
      p('Pawn', 'red', 6, 6), // 兵 7,7
      // 黑方
      p('King', 'black', 4, 0), // 将 5,1
      p('Rook', 'black', 1, 0), // 车 2,1
      p('Rook', 'black', 3, 0), // 车 4,1
      p('Bishop', 'black', 4, 2), // 象 5,3
      p('Pawn', 'black', 5, 8), // 卒 6,9
    ],
  },
  {
    id: 'zheng-xi',
    name: '征西',
    difficulty: '高级',
    goal: '',
    description: '双炮双车压制，寻找破口直击将门。',
    initialTurn: 'red',
    aiLevel: 6,
    tags: ['双炮', '双车'],
    initialPieces: [
      // 红方
      p('King', 'red', 3, 9), // 帅 4,10
      p('Bishop', 'red', 6, 9), // 相 7,10
      p('Pawn', 'red', 2, 1), // 兵 3,2
      p('Pawn', 'red', 4, 1), // 兵 5,2
      p('Cannon', 'red', 6, 3), // 炮 7,4
      p('Cannon', 'red', 6, 4), // 炮 7,5
      p('Rook', 'red', 6, 5), // 车 7,6
      p('Rook', 'red', 8, 5), // 车 9,6
      // 黑方
      p('King', 'black', 5, 0), // 将 6,1
      p('Cannon', 'black', 4, 0), // 炮 5,1
      p('Rook', 'black', 5, 2), // 车 6,3
      p('Pawn', 'black', 0, 7), // 卒 1,8
      p('Pawn', 'black', 3, 7), // 卒 4,8
      p('Pawn', 'black', 4, 8), // 卒 5,9
    ],
  },
  {
    id: 'ye-ma-cao-tian',
    name: '野马操田',
    difficulty: '中级',
    goal: '',
    description: '双车配合马与双相推进，考验火力铺垫与穿透。',
    initialTurn: 'red',
    aiLevel: 6,
    tags: ['双车', '马攻'],
    initialPieces: [
      // 红方
      p('King', 'red', 3, 9),
      p('Bishop', 'red', 2, 5),
      p('Bishop', 'red', 4, 7),
      p('Horse', 'red', 6, 4),
      p('Rook', 'red', 7, 4),
      p('Rook', 'red', 8, 4),
      p('Pawn', 'red', 2, 6),
      p('Pawn', 'red', 4, 6),
      // 黑方
      p('King', 'black', 4, 0),
      p('Advisor', 'black', 3, 0),
      p('Advisor', 'black', 4, 1),
      p('Bishop', 'black', 2, 0),
      p('Bishop', 'black', 4, 2),
      p('Rook', 'black', 1, 6),
      p('Pawn', 'black', 3, 7),
      p('Pawn', 'black', 4, 8),
    ],
  },
  {
    id: 'test',
    name: 'test',
    difficulty: '中级',
    goal: '',
    description: '测试残局配置。',
    initialTurn: 'red',
    aiLevel: 6,
    tags: ['测试'],
    initialPieces: [
      // 红方
      p('King', 'red', 5, 9), // 帅 6,10
      p('Bishop', 'red', 2, 9), // 相 3,10
      p('Pawn', 'red', 4, 1), // 兵 5,2
      p('Rook', 'red', 8, 4), // 车 9,5
      p('Rook', 'red', 8, 5), // 车 9,6
      p('Cannon', 'red', 7, 6), // 炮 8,7
      p('Cannon', 'red', 8, 6), // 炮 9,7
      // 黑方
      p('King', 'black', 3, 0), // 将 4,1
      p('Pawn', 'black', 5, 7), // 卒 6,8
      p('Pawn', 'black', 4, 8), // 卒 5,9
    ],
  },
]

function isInsideBoard(pos: ChessPosition) {
  return pos.x >= 0 && pos.x <= 8 && pos.y >= 0 && pos.y <= 9
}

function isPalacePos(pos: ChessPosition, color: ChessColor) {
  const inFile = pos.x >= 3 && pos.x <= 5
  const inRank = color === 'red' ? pos.y >= 7 && pos.y <= 9 : pos.y >= 0 && pos.y <= 2
  return inFile && inRank
}

function isOwnHalf(pos: ChessPosition, color: ChessColor) {
  return color === 'red' ? pos.y >= 5 : pos.y <= 4
}

function kingsFacing(board: (EndgamePiece | null)[][]) {
  const kingCols: Record<string, number | null> = { red: null, black: null }
  for (let x = 0; x < 9; x++) {
    let redY: number | null = null
    let blackY: number | null = null
    for (let y = 0; y < 10; y++) {
      const piece = board[x][y]
      if (piece && piece.type === 'King') {
        if (piece.color === 'red') redY = y
        else blackY = y
      }
    }
    if (redY !== null && blackY !== null) {
      let blocked = false
      for (let y = Math.min(redY, blackY) + 1; y < Math.max(redY, blackY); y++) {
        if (board[x][y]) {
          blocked = true
          break
        }
      }
      if (!blocked) return true
    }
  }
  return false
}

export function validateScenario(s: EndgameScenario): ValidationResult {
  const errors: string[] = []
  const seen = new Set<string>()
  let redKing = 0
  let blackKing = 0
  const board: (EndgamePiece | null)[][] = Array.from({ length: 9 }).map(() => Array(10).fill(null))

  s.initialPieces.forEach((piece, idx) => {
    if (!isInsideBoard(piece.position)) {
      errors.push(`[${s.name}] 棋子越界: ${piece.type}@(${piece.position.x},${piece.position.y})`)
      return
    }
    const key = `${piece.position.x},${piece.position.y}`
    if (seen.has(key)) {
      errors.push(`[${s.name}] 位置重复: ${key}`)
      return
    }
    seen.add(key)
    if (piece.type === 'King') {
      if (!isPalacePos(piece.position, piece.color)) {
        errors.push(`[${s.name}] 将/帅未在九宫: ${key}`)
      }
      piece.color === 'red' ? redKing++ : blackKing++
    }
    if (piece.type === 'Advisor' && !isPalacePos(piece.position, piece.color)) {
      errors.push(`[${s.name}] 士/仕未在九宫: ${key}`)
    }
    if (piece.type === 'Bishop' && !isOwnHalf(piece.position, piece.color)) {
      errors.push(`[${s.name}] 象/相越河: ${key}`)
    }
    board[piece.position.x][piece.position.y] = piece
  })

  if (redKing !== 1 || blackKing !== 1) {
    errors.push(`[${s.name}] 需要红帅与黑将各一枚`)
  }

  if (kingsFacing(board)) {
    errors.push(`[${s.name}] 将帅照面，布局不合法`)
  }

  if (s.initialTurn !== 'red' && s.initialTurn !== 'black') {
    errors.push(`[${s.name}] 先手颜色无效`)
  }

  return { valid: errors.length === 0, errors }
}

export function buildEngineBoard(pieces: EndgamePiece[]) {
  const board = Array.from({ length: 10 }, () => Array(9).fill(null))
  const map: Record<EndgamePieceType, string> = {
    King: 'k',
    Advisor: 'a',
    Bishop: 'b',
    Horse: 'n',
    Rook: 'r',
    Cannon: 'c',
    Pawn: 's',
  }
  pieces.forEach((p) => {
    board[p.position.y][p.position.x] = { t: map[p.type], c: p.color }
  })
  return board
}

export function quickFeasibilityCheck(scenario: EndgameScenario) {
  const validation = validateScenario(scenario)
  if (!validation.valid) return { playable: false, issues: validation.errors }
  const issues: string[] = []
  try {
    const board = buildEngineBoard(scenario.initialPieces)
    const logic = window?.logic
    if (logic && typeof logic.isCheckmate === 'function') {
      if (logic.isCheckmate(board, scenario.initialTurn)) {
        issues.push('先手一方已被将死')
      }
      if (logic.isStalemate && logic.isStalemate(board, scenario.initialTurn)) {
        issues.push('先手无子可动形成僵局')
      }
      if (logic.hasAnyLegalMoves && !logic.hasAnyLegalMoves(board, scenario.initialTurn)) {
        issues.push('先手无合法着法')
      }
    }
  } catch (e: any) {
    issues.push(`引擎校验失败: ${e?.message || e}`)
  }
  return { playable: issues.length === 0, issues }
}

export const endgameScenarios: EndgameScenario[] = scenarios.filter((s) => {
  const res = validateScenario(s)
  if (!res.valid) {
    console.warn(`[残局数据校验失败] ${s.name}:`, res.errors)
  }
  return res.valid
})

export function getScenarioById(id: string): EndgameScenario | null {
  return endgameScenarios.find((s) => s.id === id) || null
}
