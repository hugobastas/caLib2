module caLib.rules.BinaryRule;

import std.math : pow;
import std.meta : Repeat;
import std.bigint;
import std.conv : to;
import std.array : appender;
import caLib_abstract.lattice : isAnyLattice;
import caLib_abstract.neighbourhood : isAnyStaticNeighbourhood;



auto create_BinaryRule(Lt)(Lt* lattice, BigInt ruleNumber)
{
	return new BinaryRule!Lt(lattice, ruleNumber);
}



auto create_BinaryRule(Lt)(Lt* lattice, ubyte[] ruleSet)
in
{ assert(BinaryRule!Lt.configurations == ruleSet.length); }
body
{
	return new BinaryRule!Lt(lattice, ruleSet);
}



struct BinaryRule(Lt)
if(isAnyLattice!Lt && is(Lt.CellStateType : ubyte)
&& isAnyStaticNeighbourhood!(Lt.NeighbourhoodType) && Lt.NeighbourhoodType.NeighboursAmount+1 < uint.max)
{

private:

	Lt* lattice;

	BigInt ruleNumber;
	ubyte[] ruleSet;

	alias Coord = Repeat!(Lt.Dimension, int);

public:

	enum uint configurations = pow(2, Lt.NeighbourhoodType.NeighboursAmount+1); 
	BigInt maxRuleNumber;

	this(Lt* lattice, BigInt ruleNumber)
	in
	{ assert(ruleNumber <= calculateMaxRuleNumber, "rule number is to big"); }
	body
	{
		this(lattice, createRuleSetFromNumber(ruleNumber));
	}



	this(Lt* lattice, ubyte[] ruleSet)
	in
	{ assert(BinaryRule!Lt.configurations == ruleSet.length); }
	body
	{
		this.lattice = lattice;

		this.ruleSet = ruleSet;
		this.ruleNumber = createNumberFromRuleSet(ruleSet);

		maxRuleNumber = calculateMaxRuleNumber();
	}



	void applyRule()
	{
		lattice.iterate((ubyte cellState, ubyte[] neighbours, Coord c)
		{
			uint n = cellState << neighbours.length;
			foreach(i; 0 .. neighbours.length)
			{
				n += neighbours[i] << i;
			}

			return ruleSet[n];
		});

		lattice.nextGen();
	}



	BigInt getRuleNumber() { return ruleNumber; }
	ubyte[] getRuleSet() { return ruleSet.dup; }



	static BigInt calculateMaxRuleNumber()
	{
		BigInt n = BigInt("1");
		foreach(i; 0 .. configurations) { n *= 2; }
		return n-1;
	}



private:

	static  ubyte[] createRuleSetFromNumber(BigInt ruleNumber)
	out(result)
	{
		assert(BinaryRule!Lt.configurations == result.length);
	}
	body
	{
		string binaryRuleString = toBinaryString(ruleNumber);

		ubyte[] ruleSet = new ubyte[BinaryRule!Lt.configurations];
		foreach(i; 0 .. binaryRuleString.length)
		{
			ruleSet[i] = to!ubyte(
				binaryRuleString[binaryRuleString.length-1-i] - '0');
		}

		return ruleSet;
	}



	static BigInt createNumberFromRuleSet(const ubyte[] ruleSet)
	in
	{
		assert(BinaryRule!Lt.configurations == ruleSet.length);
	}
	body
	{
		BigInt n = BigInt("0");
		foreach(i; 0 .. configurations)
		{
			if(ruleSet[i] == 1)
			{
				BigInt k = BigInt("1");
				foreach(j; 0 .. i)
				{
					k *= 2;
				}
				n += k;
			}
		}
		return n;
	}



	static string toBinaryString(const BigInt num)
	{
		string hex = num.toHex();
		auto bin = appender!string();

		foreach(s; hex)
		{
			if(s != '_')
				bin.put(hexToBinary(s));
		}

		return bin.data;
	}



	static string hexToBinary(char hex)
	{
		string bin =
		[
			'0':"0000", '1':"0001", '2':"0010", '3':"0011", '4':"0100",
			'5':"0101", '6':"0110", '7':"0111", '8':"1000", '9':"1001",
			'A':"1010", 'B':"1011", 'C':"1100", 'D':"1101", 'E':"1110",
			'F':"1111"
		].get(hex,null);

		assert(bin != null);
		return bin;
	}
}



version(unittest)
{
	import caLib_abstract.rule : isRule;
	import caLib_abstract.lattice : Lattice;
	import caLib_abstract.neighbourhood : StaticNeighbourhood;
}

unittest
{
	alias lattice = Lattice!(ubyte, 2, StaticNeighbourhood!2);
	static assert(isRule!(BinaryRule!lattice));
}