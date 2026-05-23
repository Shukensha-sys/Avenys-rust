use crate::error::Result;
use crate::lexer::TokenType;
use crate::parser::ast::{DataType, Expression, Identifier, Literal, Statement};
use crate::parser::{identifier_expr_with_pos, Parser};

impl Parser {
    pub(super) fn parse_match_statement(&mut self) -> Result<Statement> {
        self.expect(TokenType::Match)?;
        let value = self.parse_match_value()?;
        self.expect(TokenType::Lbrace)?;

        let mut cases = Vec::new();
        let mut default = Vec::new();
        let mut seen_default = false;
        let mut consumed_closing_brace = false;

        loop {
            self.skip_newlines();
            if self.check(TokenType::Rbrace) {
                self.advance();
                consumed_closing_brace = true;
                break;
            }
            if !self.next_tokens_form_match_case() {
                break;
            }

            let pattern = self.parse_match_pattern()?;
            self.skip_newlines();
            self.expect(TokenType::Lbrace)?;
            self.skip_newlines();
            self.push_scope();
            self.declare_match_pattern_bindings(&pattern);
            let body = self.parse_statements_until_block_close()?;
            self.pop_scope();
            self.expect(TokenType::Rbrace)?;

            let is_default = matches!(
                &pattern,
                Expression::Identifier(Identifier { name, .. }) if name == "_"
            );
            if is_default {
                if seen_default {
                    return Err(self.error("match statement cannot contain multiple default '_' arms"));
                }
                seen_default = true;
                default = body;
            } else {
                if seen_default {
                    return Err(self.error("match statement cases cannot appear after default '_' arm"));
                }
                cases.push((pattern, body));
            }
        }

        if !consumed_closing_brace {
            self.expect(TokenType::Rbrace)?;
        }

        Ok(Statement::Match {
            value,
            cases,
            default,
        })
    }

    pub(super) fn parse_match_expression(&mut self) -> Result<Expression> {
        let value = self.parse_match_value()?;
        self.skip_newlines();
        self.expect(TokenType::Lbrace)?;
        self.skip_newlines();

        let mut cases = Vec::new();
        let mut default = None;
        let mut seen_default = false;
        let mut consumed_closing_brace = false;

        loop {
            self.skip_newlines();
            if self.check(TokenType::Rbrace) {
                self.advance();
                consumed_closing_brace = true;
                break;
            }
            if !self.next_tokens_form_match_case() {
                break;
            }

            let pattern_expr = self.parse_match_pattern()?;
            self.skip_newlines();
            self.expect(TokenType::Lbrace)?;
            self.skip_newlines();
            self.push_scope();
            self.declare_match_pattern_bindings(&pattern_expr);
            let body_expr = self.parse_expression_until_block_close()?;
            self.pop_scope();
            self.expect(TokenType::Rbrace)?;

            let is_default = matches!(
                &pattern_expr,
                Expression::Identifier(Identifier { name, .. }) if name == "_"
            );
            if is_default {
                if seen_default {
                    return Err(self.error("match expression cannot contain multiple default '_' arms"));
                }
                seen_default = true;
                default = Some(body_expr);
            } else {
                if seen_default {
                    return Err(
                        self.error("match expression cases cannot appear after default '_' arm")
                    );
                }
                cases.push((pattern_expr, body_expr));
            }

            self.skip_newlines();
        }

        if !consumed_closing_brace {
            self.expect(TokenType::Rbrace)?;
        }

        Ok(Expression::Match {
            value: Box::new(value),
            cases,
            default: Box::new(default.unwrap_or(Expression::Literal(Literal::None))),
            data_type: DataType::Unknown,
        })
    }

    fn parse_match_pattern(&mut self) -> Result<Expression> {
        let token = self.peek();
        match token.ttype {
            TokenType::Ident => {
                let name = self.advance().value.unwrap_or_default();
                if self.check(TokenType::Dot) && self.peek_n(1).ttype == TokenType::Ident {
                    self.advance();
                    let variant_name = self.advance().value.unwrap_or_default();
                    if self.check(TokenType::Lparen) {
                        self.advance();
                        let payloads = self.parse_expression_list_until(TokenType::Rparen)?;
                        self.expect(TokenType::Rparen)?;
                        let enum_name = name;
                        return Ok(Expression::EnumVariant {
                            enum_name: enum_name.clone(),
                            variant_name,
                            payloads,
                            data_type: DataType::EnumNamed(enum_name),
                        });
                    }
                    let enum_name = name;
                    return Ok(Expression::EnumVariantPath {
                        enum_name: enum_name.clone(),
                        variant_name,
                        data_type: DataType::EnumNamed(enum_name),
                    });
                }

                if self.check(TokenType::Lparen)
                    && name.chars().next().is_some_and(|c| c.is_uppercase())
                {
                    self.advance();
                    let payloads = self.parse_expression_list_until(TokenType::Rparen)?;
                    self.expect(TokenType::Rparen)?;
                    let Some(enum_name) = self.enum_variant_owners.get(&name).cloned() else {
                        return Err(self.error_at(
                            token.line,
                            token.column,
                            &format!(
                                "Cannot resolve enum variant shorthand '{}'; use Enum.{} explicitly",
                                name, name
                            ),
                        ));
                    };
                    return Ok(Expression::EnumVariant {
                        enum_name: enum_name.clone(),
                        variant_name: name,
                        payloads,
                        data_type: DataType::EnumNamed(enum_name),
                    });
                }

                Ok(identifier_expr_with_pos(&name, token.line, token.column))
            }
            TokenType::IntLit => {
                let token = self.advance();
                let val = token.value.unwrap_or_default();
                let parsed = val.parse().map_err(|_| {
                    self.error_at(
                        token.line,
                        token.column,
                        &format!("Invalid integer literal '{}'", val),
                    )
                })?;
                Ok(Expression::Literal(Literal::Int(parsed)))
            }
            TokenType::FloatLit => {
                let token = self.advance();
                let val = token.value.unwrap_or_default();
                let parsed = val.parse().map_err(|_| {
                    self.error_at(
                        token.line,
                        token.column,
                        &format!("Invalid float literal '{}'", val),
                    )
                })?;
                Ok(Expression::Literal(Literal::Float(parsed)))
            }
            TokenType::CharLit => {
                let token = self.advance();
                let val = token.value.unwrap_or_default();
                let parsed = val.parse::<u32>().map_err(|_| {
                    self.error_at(
                        token.line,
                        token.column,
                        &format!("Invalid char literal '{}'", val),
                    )
                })?;
                Ok(Expression::Literal(Literal::Char(parsed)))
            }
            TokenType::StrLit => {
                let val = self.advance().value.unwrap_or_default();
                Ok(Expression::Literal(Literal::Str(val)))
            }
            TokenType::BoolLit => {
                let val = self.advance().value.unwrap_or_default();
                Ok(Expression::Literal(Literal::Bool(val == "true")))
            }
            _ => Err(self.error("Expected pattern in match case")),
        }
    }

    fn parse_match_value(&mut self) -> Result<Expression> {
        while self.peek().ttype == TokenType::Newline {
            self.advance();
        }
        self.parse_expression()
    }

    fn next_tokens_form_match_case(&self) -> bool {
        let mut i = self.pos;
        while let Some(token) = self.tokens.get(i) {
            if token.ttype != TokenType::Newline {
                break;
            }
            i += 1;
        }

        let mut depth_paren = 0usize;
        let mut depth_bracket = 0usize;
        let mut index = i;
        while let Some(token) = self.tokens.get(index) {
            match token.ttype {
                TokenType::Rbrace if depth_paren == 0 && depth_bracket == 0 => return false,
                TokenType::Dot if depth_paren == 0 && depth_bracket == 0 => {
                    index += 1;
                    continue;
                }
                TokenType::Colon | TokenType::Eof if depth_paren == 0 && depth_bracket == 0 => {
                    return false;
                }
                TokenType::Newline => {
                    index += 1;
                    continue;
                }
                TokenType::Lparen => depth_paren += 1,
                TokenType::Rparen => depth_paren = depth_paren.saturating_sub(1),
                TokenType::Lbracket => depth_bracket += 1,
                TokenType::Rbracket => depth_bracket = depth_bracket.saturating_sub(1),
                TokenType::IntLit
                | TokenType::FloatLit
                | TokenType::CharLit
                | TokenType::StrLit
                | TokenType::BoolLit
                | TokenType::NoneLit
                    if depth_paren == 0 && depth_bracket == 0 =>
                {
                    return true;
                }
                TokenType::Ident if depth_paren == 0 && depth_bracket == 0 => return true,
                _ => {}
            }
            index += 1;
        }
        false
    }

    fn declare_match_pattern_bindings(&mut self, pattern: &Expression) {
        if let Expression::EnumVariant { payloads, .. } = pattern {
            for payload in payloads {
                if let Expression::Identifier(Identifier { name, .. }) = payload {
                    self.declare(name);
                }
            }
        }
    }
}
