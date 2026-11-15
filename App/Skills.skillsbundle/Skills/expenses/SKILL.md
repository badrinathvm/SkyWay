---
name: expenses
description: Record money the user spent, or answer questions about their spending, in Skyway. Use when the user says they paid, spent, bought, or got a receipt for something, like "I spent $42 on lunch at Nopa", "log a receipt", or "the same coffee as yesterday", or asks how much they spent, on what, or where. Not for billing a client or creating an invoice, which is money the user is owed, and not for mileage.
---

# Expenses

An expense is money the user already paid. An invoice is money a client owes the user. "I paid",
"I spent", "I bought", and "lunch was $40" are expenses. "Bill", "charge", and "invoice" are
invoices, so use the invoicing tools for those, not this skill.

## Logging an expense

When the user gave where and how much, use the Log Expense tool right away.

- **Category.** Only pass a category the user named. Otherwise leave it empty: Skyway files the
  expense the way the user filed that supplier before, which is better than a guess.
- **Currency.** Pass the currency the user said, as its code. If they didn't name one, leave it
  empty. Never convert an amount from one currency to another.
- **Date.** "Yesterday", "last Friday", and so on are the purchase date. Leave it empty for today.
- **Notes.** Put who or what it was for in the notes, like "Client lunch with Maria".

When something is missing or vague, use the Get Recent Expenses tool first:

- **"The usual", "same as yesterday", or no amount.** Use the amount of the most recent expense at
  that supplier, and tell the user which one it came from, by date. If there's none, ask.
- **Only a supplier's first word or a nickname.** If exactly one recent supplier matches, use its
  full name as it appears there. If several do, ask which one.

Before logging, check the recent expenses for one with the same supplier and amount on the same
day. If there is one, tell the user and ask whether it's a second purchase.

For several purchases in one request, log one expense per purchase.

## Answering questions about spending

Use the Get Recent Expenses tool, then answer from it: add up the expenses that match the
category, supplier, or dates the user asked about, and say how many there were.

- Add up each currency separately, and never convert between currencies. Say, for example,
  "$84.20 and €12.00".
- Totals already include tax. Mention the tax only if the user asks.
- If the question covers more time than the recent expenses go back, say how far back they go.

## Don't

- Don't log an expense when the user only asked about their spending.
- Don't make up an amount, a supplier, or a date.
