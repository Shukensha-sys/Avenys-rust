use super::*;

impl Parser {
    pub(super) fn parse_lifecycle_call_args(&mut self) -> Result<Vec<Expression>> {
        self.expect(TokenType::Colon)?;
        self.expect(TokenType::Colon)?;
        self.expect(TokenType::Lparen)?;
        let mut args = Vec::new();
        while !self.check(TokenType::Rparen) && !self.is_at_end() {
            if self.check(TokenType::Comma) {
                self.advance();
                continue;
            }
            args.push(self.parse_expression()?);
            if self.check(TokenType::Comma) {
                self.advance();
            }
        }
        self.expect(TokenType::Rparen)?;
        Ok(args)
    }

    pub(super) fn parse_new_statement(&mut self) -> Result<Statement> {
        self.expect(TokenType::NewKw)?;
        let mut args = self.parse_lifecycle_call_args()?;
        self.expect(TokenType::Colon)?;
        let declared_type = self.parse_type()?;
        let value = if args.is_empty() {
            None
        } else if args.len() == 1 {
            Some(args.remove(0))
        } else {
            Some(Expression::Tuple {
                elements: args,
                data_type: DataType::Unknown,
            })
        };
        Ok(Statement::New {
            value,
            declared_type,
        })
    }

    pub(super) fn parse_own_statement(&mut self) -> Result<Statement> {
        self.expect(TokenType::OwnKw)?;
        let mut args = self.parse_lifecycle_call_args()?;
        self.expect(TokenType::Colon)?;
        let inner_type = self.parse_type()?;
        let value = if args.is_empty() {
            None
        } else if args.len() == 1 {
            Some(args.remove(0))
        } else {
            Some(Expression::Tuple {
                elements: args,
                data_type: DataType::Unknown,
            })
        };
        Ok(Statement::Own { value, inner_type })
    }

    pub(super) fn parse_move_statement(&mut self) -> Result<Statement> {
        self.expect(TokenType::MoveKw)?;
        let mut args = self.parse_lifecycle_call_args()?;
        if args.len() != 1 {
            return Err(self.error("move:: expects exactly one source expression"));
        }
        self.expect(TokenType::To)?;
        let target = self.expect_ident()?;
        Ok(Statement::Move {
            target,
            value: args.remove(0),
        })
    }

    pub(super) fn parse_drop_statement(&mut self) -> Result<Statement> {
        self.expect(TokenType::DropKw)?;
        let mut args = self.parse_lifecycle_call_args()?;
        let value = if args.is_empty() {
            return Err(self.error("drop:: expects at least one expression"));
        } else if args.len() == 1 {
            args.remove(0)
        } else {
            Expression::Tuple {
                elements: args,
                data_type: DataType::Unknown,
            }
        };
        Ok(Statement::Drop { value })
    }
}
