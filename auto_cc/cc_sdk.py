import asyncio
from claude_code_sdk import ClaudeSDKClient, ClaudeCodeOptions
from typing import List, Dict, Optional
import os
import json
import argparse

async def process_multiple_queries(queries: List[Dict[str, str]], output_jsonl: Optional[str] = None) -> Dict[str, List[Dict]]:
    """
    Process multiple queries with individual working directories.
    
    Args:
        queries: List of dictionaries containing 'query' and 'working_dir' keys
                Example: [{"query": "How does auth work?", "working_dir": "/path/to/project1"},
                         {"query": "Explain the API", "working_dir": "/path/to/project2"}]
        output_jsonl: Optional path to JSONL file to save results incrementally
    
    Returns:
        Dictionary containing results for all queries with metadata
    """
    all_results = {
        "queries_processed": len(queries),
        "total_cost_usd": 0.0,
        "total_duration_ms": 0,
        "results": []
    }
    
    for i, query_config in enumerate(queries):
        query = query_config.get("query")
        working_dir = query_config.get("working_dir")
        
        if not query:
            print(f"Warning: Query {i+1} is empty, skipping...")
            continue
            
        print(f"Processing query {i+1}/{len(queries)}: {query}")
        if working_dir:
            print(f"Working directory: {working_dir}")
        
        try:
            # Set working directory if specified
            original_cwd = None
            if working_dir and os.path.exists(working_dir):
                original_cwd = os.getcwd()
                os.chdir(working_dir)
            elif working_dir:
                print(f"Warning: Working directory {working_dir} does not exist, using current directory")
            
            # Create client with options if working directory is specified
            options = ClaudeCodeOptions() if working_dir else None
            
            async with ClaudeSDKClient(options=options) as client:
                await client.query(query)
                
                messages = []
                result_data = None
                
                async for message in client.receive_messages():
                    messages.append(message)
                    
                    if type(message).__name__ == "ResultMessage":
                        result_data = {
                            "query_index": i + 1,
                            "query": query,
                            "working_dir": working_dir or os.getcwd(),
                            "result": message.result,
                            "cost_usd": message.total_cost_usd,
                            "duration_ms": message.duration_ms,
                            "num_turns": message.num_turns,
                            "session_id": message.session_id,
                            "status": "success"
                        }
                        
                        # Update totals
                        all_results["total_cost_usd"] += message.total_cost_usd
                        all_results["total_duration_ms"] += message.duration_ms
                        break
                
                if result_data:
                    all_results["results"].append(result_data)
                    # Save to JSONL file immediately if specified
                    if output_jsonl:
                        with open(output_jsonl, 'a', encoding='utf-8') as f:
                            f.write(json.dumps(result_data, ensure_ascii=False) + '\n')
                        print(f"Saved result {i+1} to {output_jsonl}")
                else:
                    # Handle case where no result was received
                    error_result = {
                        "query_index": i + 1,
                        "query": query,
                        "working_dir": working_dir or os.getcwd(),
                        "result": None,
                        "cost_usd": 0.0,
                        "duration_ms": 0,
                        "num_turns": 0,
                        "session_id": None,
                        "status": "no_result",
                        "error": "No result message received"
                    }
                    all_results["results"].append(error_result)
                    # Save to JSONL file immediately if specified
                    if output_jsonl:
                        with open(output_jsonl, 'a', encoding='utf-8') as f:
                            f.write(json.dumps(error_result, ensure_ascii=False) + '\n')
                        print(f"Saved error result {i+1} to {output_jsonl}")
                    
        except Exception as e:
            print(f"Error processing query {i+1}: {str(e)}")
            error_result = {
                "query_index": i + 1,
                "query": query,
                "working_dir": working_dir or os.getcwd(),
                "result": None,
                "cost_usd": 0.0,
                "duration_ms": 0,
                "num_turns": 0,
                "session_id": None,
                "status": "error",
                "error": str(e)
            }
            all_results["results"].append(error_result)
            # Save to JSONL file immediately if specified
            if output_jsonl:
                with open(output_jsonl, 'a', encoding='utf-8') as f:
                    f.write(json.dumps(error_result, ensure_ascii=False) + '\n')
                print(f"Saved error result {i+1} to {output_jsonl}")
        finally:
            # Restore original working directory
            if original_cwd:
                os.chdir(original_cwd)
    
    return all_results

def load_queries_from_jsonl(input_file: str) -> List[Dict[str, str]]:
    """
    Load queries from a JSONL file.
    
    Args:
        input_file: Path to JSONL file containing queries
        
    Returns:
        List of query dictionaries
        
    Expected JSONL format:
        {"query": "How does auth work?", "working_dir": "/path/to/project1"}
        {"query": "Explain the API", "working_dir": "/path/to/project2"}
    """
    queries = []
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                try:
                    query_data = json.loads(line)
                    if not isinstance(query_data, dict) or 'query' not in query_data:
                        print(f"Warning: Line {line_num} missing 'query' field, skipping...")
                        continue
                    queries.append(query_data)
                except json.JSONDecodeError as e:
                    print(f"Warning: Invalid JSON on line {line_num}: {e}")
                    continue
        print(f"Loaded {len(queries)} queries from {input_file}")
        return queries
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found")
        return []
    except Exception as e:
        print(f"Error reading input file {input_file}: {e}")
        return []

def print_query_summary(results: Dict, output_jsonl_file: Optional[str] = None, show_case: bool = True):
    """
    Print a concise summary of query processing results.
    
    Args:
        results: Results dictionary from process_multiple_queries
        output_jsonl_file: Path to JSONL output file if used
    """
    print(f"\n{'='*60}")
    print(f"QUERY PROCESSING SUMMARY")
    print(f"{'='*60}")
    print(f"Queries processed: {results['queries_processed']}")
    print(f"Total cost: ${results['total_cost_usd']:.4f}")
    print(f"Total duration: {results['total_duration_ms']}ms")
    if output_jsonl_file:
        print(f"Results saved to: {output_jsonl_file}")
    print(f"{'='*60}\n")
    
    # Print summary for each query without the full result content
    if show_case:
        for result in results['results']:
            status_emoji = "✅" if result['status'] == 'success' else "❌" if result['status'] == 'error' else "⚠️"
            print(f"{status_emoji} Query {result['query_index']}: {result['query'][:80]}{'...' if len(result['query']) > 80 else ''}")
            print(f"   Status: {result['status']}")
            print(f"   Working Dir: {result['working_dir']}")
            
            if result['status'] == 'success':
                print(f"   Cost: ${result['cost_usd']:.4f} | Duration: {result['duration_ms']}ms | Turns: {result['num_turns']}")
                result_preview = result['result'][:200] if result['result'] else "No result content"
                print(f"   Result Preview: {result_preview}{'...' if result['result'] and len(result['result']) > 200 else ''}")
            elif result['status'] == 'error':
                print(f"   Error: {result['error']}")
            
        print(f"{'-'*40}")

def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Process multiple Claude Code queries with individual working directories')
    parser.add_argument('--output', '-o', type=str, default='/mnt/bn/tiktok-mm-5/aiic/users/tianyu/OpenCoder/data/query_results.jsonl',
                       help='Path to JSONL output file to save results')
    parser.add_argument('--input', '-i', type=str, default=None,
                       help='Path to JSONL input file containing queries')
    parser.add_argument('--show-case', action='store_true', default=False,
                       help='Show detailed case information in console output')
    return parser.parse_args()

async def main():
    args = parse_args()
    
    # Load queries from input file or use default examples
    if args.input:
        queries = load_queries_from_jsonl(args.input)
        if not queries:
            print("No valid queries found in input file. Exiting.")
            return None
    else:
        # Default example queries
        queries = [
            {"query": "How does the data layer work?", "working_dir": None},
            {"query": "请告诉我这个工程是干嘛的", "working_dir": "/mnt/bn/tiktok-mm-5/aiic/users/tianyu/RepoLevel_Synthetic/task2_multiscript"},
            # {"query": "How are tests organized?", "working_dir": "/path/to/test/project"}
        ]
        print("Using default example queries (use --input to specify custom queries)")
    
    # Process queries
    results = await process_multiple_queries(queries, output_jsonl=args.output)
    
    # Print summary with show_case option
    print_query_summary(results, args.output, args.show_case)
    
    return results

# Run as script
if __name__ == "__main__":
    asyncio.run(main())
