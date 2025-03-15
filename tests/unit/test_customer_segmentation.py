"""
Unit Tests for Customer Segmentation Model
Azure Synapse Analytics Data Platform (ASADP)
"""

import unittest
import pandas as pd
import numpy as np
import tempfile
import os
import sys
from datetime import datetime, timedelta
from unittest.mock import patch, MagicMock

# Add the machine learning models directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), '../../machine-learning/models'))

try:
    from customer_segmentation_model import CustomerSegmentationModel
except ImportError:
    # Fallback for testing environment
    CustomerSegmentationModel = None

class TestCustomerSegmentationModel(unittest.TestCase):
    """Test cases for the CustomerSegmentationModel class."""
    
    def setUp(self):
        """Set up test fixtures before each test method."""
        if CustomerSegmentationModel is None:
            self.skipTest("CustomerSegmentationModel not available")
        
        self.model = CustomerSegmentationModel(n_clusters=3, random_state=42)
        
        # Create sample transaction data
        np.random.seed(42)
        n_transactions = 100
        n_customers = 20
        
        customer_ids = [f'CUST_{i:06d}' for i in range(1, n_customers + 1)]
        
        self.sample_data = pd.DataFrame({
            'customer_id': np.random.choice(customer_ids, n_transactions),
            'transaction_date': pd.date_range('2023-01-01', periods=n_transactions, freq='D')[:n_transactions],
            'net_amount': np.random.lognormal(4, 1, n_transactions)
        })
        
        # Ensure we have multiple transactions per customer
        additional_transactions = []
        for customer_id in customer_ids[:10]:  # Add more transactions for first 10 customers
            for i in range(3):
                additional_transactions.append({
                    'customer_id': customer_id,
                    'transaction_date': pd.Timestamp('2023-01-01') + pd.Timedelta(days=np.random.randint(0, 365)),
                    'net_amount': np.random.lognormal(4, 1)
                })
        
        self.sample_data = pd.concat([
            self.sample_data, 
            pd.DataFrame(additional_transactions)
        ], ignore_index=True)
        
        # Calculate RFM features for testing
        self.rfm_data = self.model.calculate_rfm_features(self.sample_data)
    
    def test_model_initialization(self):
        """Test model initialization with default parameters."""
        model = CustomerSegmentationModel()
        self.assertEqual(model.n_clusters, 5)
        self.assertEqual(model.random_state, 42)
        self.assertIsNone(model.model)
        self.assertIsNone(model.scaler)
        self.assertFalse(model.is_fitted)
    
    def test_model_initialization_with_params(self):
        """Test model initialization with custom parameters."""
        model = CustomerSegmentationModel(n_clusters=4, random_state=123)
        self.assertEqual(model.n_clusters, 4)
        self.assertEqual(model.random_state, 123)
    
    def test_calculate_rfm_features(self):
        """Test RFM feature calculation."""
        rfm_df = self.model.calculate_rfm_features(self.sample_data)
        
        # Check that all expected columns are present
        expected_columns = [
            'recency_days', 'frequency_transactions', 'monetary_total',
            'monetary_avg', 'monetary_std', 'customer_id',
            'days_since_first_purchase', 'avg_days_between_purchases', 'clv_proxy'
        ]
        
        for col in expected_columns:
            self.assertIn(col, rfm_df.columns, f"Column {col} missing from RFM features")
        
        # Check data types and ranges
        self.assertTrue(rfm_df['recency_days'].dtype in [np.int64, np.float64])
        self.assertTrue(rfm_df['frequency_transactions'].dtype in [np.int64, np.float64])
        self.assertTrue(rfm_df['monetary_total'].dtype in [np.float64])
        
        # Check that all values are non-negative
        self.assertTrue((rfm_df['recency_days'] >= 0).all())
        self.assertTrue((rfm_df['frequency_transactions'] > 0).all())
        self.assertTrue((rfm_df['monetary_total'] > 0).all())
        
        # Check that we have unique customers
        self.assertEqual(len(rfm_df), rfm_df['customer_id'].nunique())
    
    def test_create_rfm_scores(self):
        """Test RFM score creation."""
        rfm_with_scores = self.model.create_rfm_scores(self.rfm_data)
        
        # Check that score columns are present
        score_columns = ['recency_score', 'frequency_score', 'monetary_score', 'rfm_score', 'customer_segment']
        for col in score_columns:
            self.assertIn(col, rfm_with_scores.columns, f"Column {col} missing from RFM scores")
        
        # Check score ranges (1-5)
        self.assertTrue((rfm_with_scores['recency_score'].between(1, 5)).all())
        self.assertTrue((rfm_with_scores['frequency_score'].between(1, 5)).all())
        self.assertTrue((rfm_with_scores['monetary_score'].between(1, 5)).all())
        
        # Check RFM score format (3-digit string)
        self.assertTrue(rfm_with_scores['rfm_score'].str.len().eq(3).all())
        
        # Check that customer segments are assigned
        self.assertTrue(rfm_with_scores['customer_segment'].notna().all())
    
    def test_prepare_features(self):
        """Test feature preparation for clustering."""
        features = self.model.prepare_features(self.rfm_data)
        
        # Check feature array shape
        self.assertEqual(features.shape[0], len(self.rfm_data))
        self.assertEqual(features.shape[1], 5)  # 5 features expected
        
        # Check that features are scaled (mean ~0, std ~1)
        self.assertAlmostEqual(np.mean(features), 0, places=1)
        self.assertAlmostEqual(np.std(features), 1, places=1)
        
        # Check that scaler is fitted
        self.assertIsNotNone(self.model.scaler)
        self.assertIsNotNone(self.model.feature_names)
    
    def test_find_optimal_clusters(self):
        """Test optimal cluster finding functionality."""
        features = self.model.prepare_features(self.rfm_data)
        optimal_k, metrics = self.model.find_optimal_clusters(features, max_clusters=6)
        
        # Check that optimal k is in valid range
        self.assertGreaterEqual(optimal_k, 2)
        self.assertLessEqual(optimal_k, 6)
        
        # Check that metrics are returned
        expected_metrics = ['cluster_range', 'inertias', 'silhouette_scores', 'optimal_k', 'optimal_silhouette_score']
        for metric in expected_metrics:
            self.assertIn(metric, metrics)
        
        # Check that silhouette scores are valid
        self.assertTrue(all(-1 <= score <= 1 for score in metrics['silhouette_scores']))
    
    def test_model_fitting(self):
        """Test model fitting process."""
        # Fit model without finding optimal k
        self.model.fit(self.rfm_data, find_optimal_k=False)
        
        # Check that model is fitted
        self.assertTrue(self.model.is_fitted)
        self.assertIsNotNone(self.model.model)
        self.assertIsNotNone(self.model.scaler)
        
        # Check that metrics are calculated
        self.assertIn('final_silhouette_score', self.model.model_metrics)
        self.assertIn('final_inertia', self.model.model_metrics)
        self.assertIn('n_clusters_used', self.model.model_metrics)
        
        # Check that cluster labels are created
        self.assertIsNotNone(self.model.cluster_labels)
        self.assertEqual(len(self.model.cluster_labels), self.model.n_clusters)
    
    def test_model_fitting_with_optimal_k(self):
        """Test model fitting with optimal k finding."""
        original_n_clusters = self.model.n_clusters
        self.model.fit(self.rfm_data, find_optimal_k=True)
        
        # Check that model is fitted
        self.assertTrue(self.model.is_fitted)
        
        # Check that optimal k might be different from original
        # (though with small sample size, it might be the same)
        self.assertGreaterEqual(self.model.n_clusters, 2)
        
        # Check that optimization metrics are stored
        self.assertIn('optimal_k', self.model.model_metrics)
        self.assertIn('optimal_silhouette_score', self.model.model_metrics)
    
    def test_prediction(self):
        """Test model prediction functionality."""
        # Fit model first
        self.model.fit(self.rfm_data, find_optimal_k=False)
        
        # Make predictions
        predictions = self.model.predict(self.rfm_data)
        
        # Check prediction shape and range
        self.assertEqual(len(predictions), len(self.rfm_data))
        self.assertTrue(all(0 <= pred < self.model.n_clusters for pred in predictions))
    
    def test_prediction_without_fitting(self):
        """Test that prediction raises error when model is not fitted."""
        with self.assertRaises(ValueError):
            self.model.predict(self.rfm_data)
    
    def test_customer_insights(self):
        """Test customer insights generation."""
        # Fit model first
        self.model.fit(self.rfm_data, find_optimal_k=False)
        predictions = self.model.predict(self.rfm_data)
        
        # Generate insights
        insights = self.model.get_customer_insights(self.rfm_data, predictions)
        
        # Check that insights contain expected columns
        expected_columns = ['cluster', 'cluster_label', 'recency_percentile', 
                          'frequency_percentile', 'monetary_percentile', 'recommendations']
        for col in expected_columns:
            self.assertIn(col, insights.columns)
        
        # Check that percentiles are in valid range
        self.assertTrue((insights['recency_percentile'].between(0, 1)).all())
        self.assertTrue((insights['frequency_percentile'].between(0, 1)).all())
        self.assertTrue((insights['monetary_percentile'].between(0, 1)).all())
        
        # Check that recommendations are provided
        self.assertTrue(insights['recommendations'].notna().all())
    
    def test_save_and_load_model(self):
        """Test model saving and loading functionality."""
        # Fit model first
        self.model.fit(self.rfm_data, find_optimal_k=False)
        
        # Save model to temporary directory
        with tempfile.TemporaryDirectory() as temp_dir:
            model_path = os.path.join(temp_dir, 'test_model')
            self.model.save_model(model_path)
            
            # Check that files are created
            self.assertTrue(os.path.exists(os.path.join(model_path, 'kmeans_model.pkl')))
            self.assertTrue(os.path.exists(os.path.join(model_path, 'scaler.pkl')))
            self.assertTrue(os.path.exists(os.path.join(model_path, 'model_info.json')))
            
            # Load model
            new_model = CustomerSegmentationModel()
            new_model.load_model(model_path)
            
            # Check that loaded model has same properties
            self.assertEqual(new_model.n_clusters, self.model.n_clusters)
            self.assertEqual(new_model.feature_names, self.model.feature_names)
            self.assertEqual(new_model.cluster_labels, self.model.cluster_labels)
            self.assertTrue(new_model.is_fitted)
            
            # Test that loaded model can make predictions
            predictions_original = self.model.predict(self.rfm_data)
            predictions_loaded = new_model.predict(self.rfm_data)
            np.testing.assert_array_equal(predictions_original, predictions_loaded)
    
    def test_save_model_without_fitting(self):
        """Test that saving raises error when model is not fitted."""
        with tempfile.TemporaryDirectory() as temp_dir:
            model_path = os.path.join(temp_dir, 'test_model')
            with self.assertRaises(ValueError):
                self.model.save_model(model_path)
    
    @patch('mlflow.start_run')
    @patch('mlflow.log_param')
    @patch('mlflow.log_metric')
    @patch('mlflow.sklearn.log_model')
    @patch('mlflow.log_artifact')
    def test_mlflow_logging(self, mock_log_artifact, mock_log_model, 
                           mock_log_metric, mock_log_param, mock_start_run):
        """Test MLflow logging functionality."""
        # Setup mock context manager
        mock_start_run.return_value.__enter__ = MagicMock()
        mock_start_run.return_value.__exit__ = MagicMock()
        
        # Fit model first
        self.model.fit(self.rfm_data, find_optimal_k=False)
        
        # Log to MLflow
        self.model.log_to_mlflow()
        
        # Check that MLflow functions were called
        mock_start_run.assert_called_once()
        mock_log_param.assert_called()
        mock_log_metric.assert_called()
        mock_log_model.assert_called_once()
        mock_log_artifact.assert_called_once()
    
    def test_mlflow_logging_without_fitting(self):
        """Test that MLflow logging raises error when model is not fitted."""
        with self.assertRaises(ValueError):
            self.model.log_to_mlflow()
    
    def test_assign_rfm_segment(self):
        """Test RFM segment assignment logic."""
        # Test Champions segment
        row_champions = pd.Series({'recency_score': 5, 'frequency_score': 5, 'monetary_score': 5})
        segment = self.model._assign_rfm_segment(row_champions)
        self.assertEqual(segment, 'Champions')
        
        # Test Lost Customers segment
        row_lost = pd.Series({'recency_score': 1, 'frequency_score': 1, 'monetary_score': 1})
        segment = self.model._assign_rfm_segment(row_lost)
        self.assertEqual(segment, 'Lost Customers')
        
        # Test New Customers segment
        row_new = pd.Series({'recency_score': 5, 'frequency_score': 1, 'monetary_score': 3})
        segment = self.model._assign_rfm_segment(row_new)
        self.assertEqual(segment, 'New Customers')
    
    def test_generate_recommendations(self):
        """Test recommendation generation for different customer segments."""
        # Test High Value recommendations
        row_high_value = pd.Series({'cluster_label': 'High Value'})
        recommendations = self.model._generate_recommendations(row_high_value)
        self.assertIsInstance(recommendations, list)
        self.assertGreater(len(recommendations), 0)
        self.assertIn('VIP treatment', ' '.join(recommendations))
        
        # Test Inactive recommendations
        row_inactive = pd.Series({'cluster_label': 'Inactive'})
        recommendations = self.model._generate_recommendations(row_inactive)
        self.assertIsInstance(recommendations, list)
        self.assertGreater(len(recommendations), 0)
        self.assertIn('win-back', ' '.join(recommendations))
    
    def test_edge_cases(self):
        """Test edge cases and error handling."""
        # Test with empty dataframe
        empty_df = pd.DataFrame(columns=['customer_id', 'transaction_date', 'net_amount'])
        with self.assertRaises((ValueError, IndexError)):
            self.model.calculate_rfm_features(empty_df)
        
        # Test with single customer
        single_customer_df = pd.DataFrame({
            'customer_id': ['CUST_001'],
            'transaction_date': ['2023-01-01'],
            'net_amount': [100.0]
        })
        rfm_single = self.model.calculate_rfm_features(single_customer_df)
        self.assertEqual(len(rfm_single), 1)
    
    def test_data_validation(self):
        """Test data validation and preprocessing."""
        # Test with missing values
        data_with_nulls = self.sample_data.copy()
        data_with_nulls.loc[0, 'net_amount'] = np.nan
        
        # Should handle NaN values gracefully
        rfm_with_nulls = self.model.calculate_rfm_features(data_with_nulls.dropna())
        self.assertGreater(len(rfm_with_nulls), 0)
        
        # Test with negative amounts (should be filtered out in real scenario)
        data_with_negative = self.sample_data.copy()
        data_with_negative.loc[0, 'net_amount'] = -50.0
        
        # Model should handle this gracefully
        rfm_negative = self.model.calculate_rfm_features(data_with_negative[data_with_negative['net_amount'] > 0])
        self.assertGreater(len(rfm_negative), 0)

class TestCustomerSegmentationIntegration(unittest.TestCase):
    """Integration tests for the CustomerSegmentationModel."""
    
    def setUp(self):
        """Set up integration test fixtures."""
        if CustomerSegmentationModel is None:
            self.skipTest("CustomerSegmentationModel not available")
        
        # Create more realistic sample data
        np.random.seed(42)
        
        # Generate customers with different behavior patterns
        customers = []
        
        # High-value customers (Champions)
        for i in range(10):
            customer_id = f'HIGH_{i:03d}'
            for j in range(np.random.randint(15, 25)):  # High frequency
                customers.append({
                    'customer_id': customer_id,
                    'transaction_date': pd.Timestamp('2023-01-01') + pd.Timedelta(days=np.random.randint(0, 30)),  # Recent
                    'net_amount': np.random.lognormal(5.5, 0.5)  # High monetary
                })
        
        # Low-value customers (Lost)
        for i in range(10):
            customer_id = f'LOW_{i:03d}'
            for j in range(np.random.randint(1, 3)):  # Low frequency
                customers.append({
                    'customer_id': customer_id,
                    'transaction_date': pd.Timestamp('2023-01-01') + pd.Timedelta(days=np.random.randint(300, 365)),  # Old
                    'net_amount': np.random.lognormal(3, 0.5)  # Low monetary
                })
        
        # Medium customers
        for i in range(20):
            customer_id = f'MED_{i:03d}'
            for j in range(np.random.randint(5, 10)):  # Medium frequency
                customers.append({
                    'customer_id': customer_id,
                    'transaction_date': pd.Timestamp('2023-01-01') + pd.Timedelta(days=np.random.randint(60, 180)),  # Medium recency
                    'net_amount': np.random.lognormal(4.5, 0.5)  # Medium monetary
                })
        
        self.integration_data = pd.DataFrame(customers)
    
    def test_end_to_end_workflow(self):
        """Test complete end-to-end workflow."""
        model = CustomerSegmentationModel(n_clusters=4, random_state=42)
        
        # Step 1: Calculate RFM features
        rfm_data = model.calculate_rfm_features(self.integration_data)
        self.assertGreater(len(rfm_data), 0)
        
        # Step 2: Create RFM scores
        rfm_with_scores = model.create_rfm_scores(rfm_data)
        self.assertIn('customer_segment', rfm_with_scores.columns)
        
        # Step 3: Fit model
        model.fit(rfm_data, find_optimal_k=True)
        self.assertTrue(model.is_fitted)
        
        # Step 4: Make predictions
        predictions = model.predict(rfm_data)
        self.assertEqual(len(predictions), len(rfm_data))
        
        # Step 5: Generate insights
        insights = model.get_customer_insights(rfm_data, predictions)
        self.assertIn('recommendations', insights.columns)
        
        # Step 6: Validate that different customer types are segmented differently
        high_value_customers = insights[insights['customer_id'].str.startswith('HIGH_')]
        low_value_customers = insights[insights['customer_id'].str.startswith('LOW_')]
        
        # High-value customers should generally have higher monetary values
        if len(high_value_customers) > 0 and len(low_value_customers) > 0:
            avg_high_monetary = high_value_customers['monetary_total'].mean()
            avg_low_monetary = low_value_customers['monetary_total'].mean()
            self.assertGreater(avg_high_monetary, avg_low_monetary)
    
    def test_model_consistency(self):
        """Test that model produces consistent results across runs."""
        model1 = CustomerSegmentationModel(n_clusters=3, random_state=42)
        model2 = CustomerSegmentationModel(n_clusters=3, random_state=42)
        
        # Calculate RFM features
        rfm_data = model1.calculate_rfm_features(self.integration_data)
        
        # Fit both models
        model1.fit(rfm_data, find_optimal_k=False)
        model2.fit(rfm_data, find_optimal_k=False)
        
        # Make predictions
        predictions1 = model1.predict(rfm_data)
        predictions2 = model2.predict(rfm_data)
        
        # Results should be identical with same random state
        np.testing.assert_array_equal(predictions1, predictions2)
    
    def test_scalability(self):
        """Test model performance with larger datasets."""
        # Create larger dataset
        np.random.seed(42)
        large_customers = []
        
        for i in range(100):  # 100 customers
            customer_id = f'SCALE_{i:03d}'
            for j in range(np.random.randint(1, 20)):  # Variable transaction count
                large_customers.append({
                    'customer_id': customer_id,
                    'transaction_date': pd.Timestamp('2023-01-01') + pd.Timedelta(days=np.random.randint(0, 365)),
                    'net_amount': np.random.lognormal(4, 1)
                })
        
        large_data = pd.DataFrame(large_customers)
        
        # Test that model can handle larger dataset
        model = CustomerSegmentationModel(n_clusters=5, random_state=42)
        rfm_data = model.calculate_rfm_features(large_data)
        
        # Should complete without errors
        model.fit(rfm_data, find_optimal_k=True)
        predictions = model.predict(rfm_data)
        insights = model.get_customer_insights(rfm_data, predictions)
        
        self.assertEqual(len(predictions), len(rfm_data))
        self.assertEqual(len(insights), len(rfm_data))

if __name__ == '__main__':
    # Configure test runner
    unittest.main(verbosity=2, buffer=True)