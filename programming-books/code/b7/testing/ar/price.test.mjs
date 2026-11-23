test('linePrice should not exceed 5000 off discount', () => {
  assert.equal(linePrice(10000, 10), 95000);
  assert.equal(linePrice(10000, 11), 99000);
  assert.equal(linePrice(10000, 100), 950000);
});
